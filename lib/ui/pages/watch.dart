import 'dart:async';
import 'dart:io';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/data/animeSpecificPreference.dart';
import 'package:animestream/ui/models/doubleTapDectector.dart';
import 'package:animestream/ui/models/widgets/subtitles/subViewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/data/watching.dart';
import 'package:animestream/ui/models/widgets/player/playerUtils.dart';
import 'package:animestream/ui/models/providers/playerDataProvider.dart';
import 'package:animestream/ui/models/providers/playerProvider.dart';
import 'package:animestream/ui/models/providers/themeProvider.dart';
import 'package:animestream/ui/models/watchPageUtil.dart';
import 'package:animestream/ui/models/widgets/player/customControls.dart';
import 'package:animestream/ui/models/widgets/player/desktopControls.dart';

class Watch extends StatefulWidget {
  final VideoController controller;
  final bool localSource;
  const Watch({
    super.key,
    required this.controller,
    this.localSource = false,
  });

  @override
  State<Watch> createState() => _WatchState();
}

class _WatchState extends State<Watch> {
  late VideoController controller;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    controller = widget.controller;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  void _initialize() async {
    /// Set black title bar
    context.read<AppProvider>().setTitlebarColor(appTheme.backgroundColor);

    final dataProvider = context.read<PlayerDataProvider>();

    debugPrint("Initializing stream ${dataProvider.state.currentStream}");

    dataProvider.initSubsettings();

    if (!widget.localSource) {
      await dataProvider.extractCurrentStreamQualities();

      final q = dataProvider.getPreferredQualityStreamFromQualities();

      dataProvider.updateCurrentQuality(q);

      await controller.initiateVideo(q['link']!, headers: dataProvider.state.currentStream.customHeaders);
    } else {
      await controller.initiateVideo(dataProvider.state.currentStream.link, offline: true);
    }

    final lastWatchDuration = (((dataProvider.lastWatchDuration ?? 0) / 100) * (controller.duration ?? 1)).toInt();

    // await dataProvider.updateDiscordPresence();

    // Seek to last watched part
    await controller.seekTo(Duration(milliseconds: lastWatchDuration)); //percentage to value

    if (mounted) context.read<PlayerProvider>().toggleSubs(action: dataProvider.state.currentStream.subtitle != null);

    // Placed here for safety. placing it above might cause issues with custom controls functions
    setState(() {
      isInitiated = true;
    });

    controller.addListener(_listener);
  }

  void _listener() {
    if (!mounted) return;

    final playerProvider = context.read<PlayerProvider>();
    final dataProvider = context.read<PlayerDataProvider>();

    if (playerProvider.state.controlsVisible) {
      hideControlsOnTimeout(dataProvider, playerProvider);
    }

    final playState = (controller.isBuffering ?? false)
        ? PlayerState.buffering
        : (controller.isPlaying ?? false)
            ? PlayerState.playing
            : PlayerState.paused;

    playerProvider.updatePlayState(playState);

    final currentPositionInSeconds = (controller.position ?? 0) ~/ 1000;
    final durationInSeconds = (controller.duration ?? 0) ~/ 1000;

    final newState = dataProvider.state.copyWith(
      currentTimeStamp: getFormattedTime(currentPositionInSeconds),
      maxTimeStamp: getFormattedTime(durationInSeconds),
      sliderValue: currentPositionInSeconds,
    );

    // Update timestamps and slider position
    dataProvider.update(newState);

    playerProvider.handleWakelock(); // Yes, it handles wakelock state

    if (!widget.localSource) {
      final currentByTotal = (controller.position ?? 0) / (controller.duration ?? 0);
      if (currentByTotal * 100 >= 75 && !dataProvider.state.preloadStarted && (controller.isPlaying ?? false)) {
        dataProvider.preloadNextEpisode();
        updateWatching(
          dataProvider.showId,
          dataProvider.showTitle,
          dataProvider.state.currentEpIndex + 1,
          dataProvider.altDatabases,
        );
      }
    }

    final finalEpReached = dataProvider.state.currentEpIndex + 1 == dataProvider.epLinks.length;

    //play the loaded episode if equal to duration
    if (!finalEpReached &&
        controller.duration != null &&
        (controller.position ?? 0) / 1000 == (controller.duration ?? 0) / 1000) {
      if (controller.isPlaying ?? false) {
        controller.pause();
      }
      playerProvider.playPreloadedEpisode(dataProvider);
    }
  }

  void hideControlsOnTimeout(PlayerDataProvider dp, PlayerProvider pp) {
    if (_controlsTimer == null && (controller.isPlaying ?? false)) {
      _controlsTimer = Timer(Duration(seconds: 5), () {
        if (controller.isPlaying ?? false) {
          pp.toggleControlsVisibility(action: false);
        }
        _controlsTimer = null;
      });
    }
  }

  Timer? _controlsTimer = null;

  Timer? pointerHideTimer = null;

  // This is required to avoid *controller is not initiate error*
  bool isInitiated = false;

  // Just a smol logic to handle taps since gesture dectector doesnt do the job with double taps
  Timer? _tapTimer;
  int lastTapTime = 0;
  final int doubleTapThreshold = 200; // in ms

  bool _showRewindAnim = false;
  bool _showForwardAnim = false;
  Timer? _animTimer;

  void _showFastForwardAnim(bool isForward) {
    skipCount++;

    _animTimer?.cancel();

    setState(() {
      if (isForward) {
        _showForwardAnim = true;
        _showRewindAnim = false;
      } else {
        _showRewindAnim = true;
        _showForwardAnim = false;
      }
    });

    _animTimer = Timer(Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showRewindAnim = false;
          _showForwardAnim = false;
        });
      }
    });
  }

  void _handleTap() {
    if (_tapTimer != null && _tapTimer!.isActive) {
      // Double tap
      _tapTimer!.cancel();
      _handleDoubleTap();
    } else {
      // Single tap
      _tapTimer = Timer(Duration(milliseconds: doubleTapThreshold), () {
        _handleSingleTap();
      });
    }
  }

  void _handleSingleTap() {
    final playerProvider = context.read<PlayerProvider>();
    playerProvider.toggleControlsVisibility();
    if (!playerProvider.state.controlsVisible) {
      _controlsTimer?.cancel();
      _controlsTimer = null;
    }
  }

  void _handleDoubleTap() {
    if (!Platform.isWindows) return;
    final themeProvider = context.read<AppProvider>();
    themeProvider.setFullScreen(!themeProvider.isFullScreen);
  }

  bool hidePointer = false;

  // for tap gesures
  bool lTapped = false, rTapped = false;

  int skipCount = 0;

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<PlayerProvider>();
    final playerDataProvider = context.watch<PlayerDataProvider>();

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        // save the last watched duration
        final double watchPercentage = isInitiated ? ((controller.position ?? 0) / controller.duration!) : 0;
        addLastWatchedDuration(
            playerDataProvider.showId.toString(), {playerDataProvider.state.currentEpIndex + 1: watchPercentage * 100});
        await context.read<AppProvider>()
          ..setFullScreen(false)
          ..setTitlebarColor(null);
        // playerDataProvider.clearDiscordPresence();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Padding(
          padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
          child: Listener(
            onPointerHover: (event) {
              // Hide the pointer when controls arent visible and mouse is unmoved for 3 seconds
              if (playerProvider.state.controlsVisible) return;
              if (hidePointer) {
                setState(() {
                  hidePointer = false;
                });
              }
              pointerHideTimer?.cancel();
              pointerHideTimer = Timer(Duration(seconds: 3), () {
                print("Hiding pointer...");
                if (mounted)
                  setState(() {
                    hidePointer = true;
                    pointerHideTimer = null;
                  });
              });
            },
            child: MouseRegion(
              cursor: playerProvider.state.controlsVisible || !hidePointer
                  ? SystemMouseCursors.basic
                  : SystemMouseCursors.none,
              child: GestureDetector(
                // behavior: HitTestBehavior.opaque,
                onTap: _handleTap,
                child: Stack(
                  children: [
                    Player(controller),
                    if (playerProvider.state.showSubs && playerDataProvider.state.currentStream.subtitle != null)
                      SubViewer(
                        controller: controller,
                        format: SubtitleFormat.fromName(
                            playerDataProvider.state.currentStream.subtitleFormat ?? SubtitleFormat.ASS.name),
                        subtitleSource: playerDataProvider.state.currentStream.subtitle!,
                        settings: playerDataProvider.subtitleSettings,
                        headers: playerDataProvider.state.currentStream.customHeaders,
                      ),
                    isInitiated
                        ? AnimatedOpacity(
                            duration: Duration(milliseconds: 150),
                            opacity: playerProvider.state.controlsVisible ? 1 : 0,
                            child: Stack(
                              children: [
                                IgnorePointer(ignoring: true, child: overlay()),
                                IgnorePointer(
                                    ignoring: !playerProvider.state.controlsVisible,
                                    child: Platform.isWindows ? Desktopcontrols() : Controls()),
                              ],
                            ),
                          )
                        : Platform.isWindows
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10, left: 10),
                                    child: IconButton(
                                        onPressed: () => Navigator.pop(context),
                                        icon: Icon(
                                          Icons.arrow_back,
                                          color: Colors.white,
                                          size: 35,
                                        )),
                                  ),
                                  PlayerLoadingWidget(),
                                  SizedBox.shrink()
                                ],
                              )
                            : Container(),
                    Container(
                      // margin: MediaQuery.paddingOf(context),
                      child: Row(children: [
                        Expanded(
                          // flex: 2,
                          child: DoubleTapDectector(
                            behavior: HitTestBehavior.translucent,
                            onDoubleTap: () {
                              playerProvider.fastForward(-(currentUserSettings?.skipDuration ?? 10));
                              if (!_showRewindAnim) skipCount = 0;
                              _showFastForwardAnim(false);
                            },
                          ),
                        ),
                        Expanded(
                          child: Container(),
                          flex: 1,
                        ),
                        Expanded(
                          // flex: 2,
                          child: DoubleTapDectector(
                            behavior: HitTestBehavior.translucent,
                            onDoubleTap: () {
                              playerProvider.fastForward(currentUserSettings?.skipDuration ?? 10);
                              if (!_showForwardAnim) skipCount = 0;
                              _showFastForwardAnim(true);
                            },
                          ),
                        ),
                      ]),
                    ),
                    _skipIndicators(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IgnorePointer _skipIndicators() {
    return IgnorePointer(
      ignoring: true,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 100),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedOpacity(
                duration: Duration(milliseconds: 500),
                opacity: _showRewindAnim ? 1 : 0,
                child: AnimatedSlide(
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  offset: Offset(_showRewindAnim ? 0 : -1, 0),
                  child: Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: appTheme.backgroundSubColor.withAlpha(200),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      " - ${(currentUserSettings?.skipDuration ?? 10) * skipCount}s",
                      style: TextStyle(
                        fontFamily: "Rubik",
                        fontSize: 23,
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedOpacity(
                duration: Duration(milliseconds: 500),
                opacity: _showForwardAnim ? 1 : 0,
                child: AnimatedSlide(
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  offset: Offset(_showForwardAnim ? 0 : 1, 0),
                  child: Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: appTheme.backgroundSubColor.withAlpha(200),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      "+ ${(currentUserSettings?.skipDuration ?? 10) * skipCount}s",
                      style: TextStyle(
                        fontFamily: "Rubik",
                        fontSize: 23,
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Container overlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [
              Color.fromARGB(220, 0, 0, 0),
              Colors.transparent,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.7]),
      ),
      child: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [
                  Color.fromARGB(220, 0, 0, 0),
                  Colors.transparent,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: [0.0, 0.7])),
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
    if (controller.duration != null && controller.duration! > 0) {
      //store the exact percentage of watched
      print("[PLAYER] SAVED WATCH DURATION");
      controller.removeListener(_listener);
      controller.dispose();
      _controlsTimer?.cancel();
      _tapTimer?.cancel();

      super.dispose();
    }
  }
}
