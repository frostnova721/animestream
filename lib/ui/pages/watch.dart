import 'dart:async';
import 'dart:io';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/data/animeSpecificPreference.dart';
import 'package:animestream/core/data/types.dart';
import 'package:animestream/ui/models/doubleTapDectector.dart';
import 'package:animestream/ui/models/playerControllers/betterPlayer.dart';
import 'package:animestream/ui/models/widgets/player/controls.dart';
import 'package:animestream/ui/models/widgets/subtitles/subViewer.dart';
import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/data/watching.dart';
import 'package:animestream/ui/models/widgets/player/playerUtils.dart';
import 'package:animestream/ui/models/providers/playerDataProvider.dart';
import 'package:animestream/ui/models/providers/playerProvider.dart';
import 'package:animestream/ui/models/providers/appProvider.dart';
import 'package:animestream/ui/models/playerControllers/videoController.dart';

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

class _WatchState extends State<Watch> with WidgetsBindingObserver {
  late VideoController controller;

  @override
  void initState() {
    super.initState();
    setWatchMode();

    controller = widget.controller;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.inactive && (currentUserSettings?.enablePipOnMinimize ?? false)) {
      context.read<PlayerProvider>().setPip(true);
    }
    // else if(state == AppLifecycleState.resumed) {
    //   context.read<PlayerProvider>().setPip(false);
    //   setWatchMode();
    // }
  }

  void setWatchMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _initialize() async {
    /// Set black title bar
    context.read<AppProvider>().setTitlebarColor(appTheme.backgroundColor);

    final dataProvider = context.read<PlayerDataProvider>();

    debugPrint("[PLAYER] Initializing stream ${dataProvider.state.currentStream}");

    dataProvider.initSubsettings();

    if (!widget.localSource) {
      await dataProvider.extractCurrentStreamQualities();

      final q = dataProvider.getPreferredQualityStreamFromQualities();

      dataProvider.updateCurrentQuality(q);

      await controller.initiateVideo(dataProvider.state.currentStream.url,
          headers: dataProvider.state.currentStream.customHeaders);

      controller.setQuality(q);

      // Fetch those skips
      dataProvider.getSkipTimesForCurrentEpisode(videoDuration: (controller.duration ?? 0).toDouble());

      if (dataProvider.state.audioTracks.isNotEmpty) {
        // gamble on this setting :)
        dataProvider.updateCurrentAudioTrack(dataProvider.state.audioTracks.first);
        controller.setAudioTrack(dataProvider.state.currentAudioTrack);
      } else {
        print("[PLAYER] Couldnt find audio tracks for this stream");
      }
    } else {
      await controller.initiateVideo(dataProvider.state.currentStream.url, offline: true);
    }

    final lastWatchPct = (dataProvider.lastWatchDuration ?? 0).clamp(0, 100);
    final totalMs = controller.duration ?? 0;
    final lastWatchDuration = totalMs <= 0 ? 0 : ((lastWatchPct / 100) * totalMs).toInt();

    // await dataProvider.updateDiscordPresence();

    // Seek to last watched part
    await controller.seekTo(Duration(milliseconds: lastWatchDuration)); //percentage to value

    if (mounted) context.read<PlayerProvider>().toggleSubs(action: dataProvider.state.currentStream.subtitle != null);

    // Placed here for safety. placing it above might cause issues with custom controls functions
    setState(() {
      isInitiated = true;
    });

    controller.addListener(_listener);

    // Since pip is only for android! (f* IOS)
    if (Platform.isAndroid) {
      try {
        // quirky hack... but we gotta do what we gotta do
        (controller as BetterPlayerWrapper).controller.addEventsListener((ev) {
          if (ev.betterPlayerEventType == BetterPlayerEventType.pipStop) {
            // The delay is required (cus its ignored without the delay for some reason)
            Future.delayed(Duration(milliseconds: 200), () {
              if (mounted) {
                setWatchMode();
              }
            });
          }
        });
      } catch (e) {
        print("[PLAYER] PiP listener couldnt be added: $e");
      }
    }
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

    if ((currentUserSettings?.autoOpEdSkip ?? false) && !_isSkippingOpOrEd) {
      final isAtOp = dataProvider.state.opSkip != null &&
          currentPositionInSeconds >= dataProvider.state.opSkip!.start &&
          currentPositionInSeconds <= dataProvider.state.opSkip!.end;

      final isAtEd = dataProvider.state.edSkip != null &&
          currentPositionInSeconds >= dataProvider.state.edSkip!.start &&
          currentPositionInSeconds <= dataProvider.state.edSkip!.end - 1;

      if (isAtOp) {
        _isSkippingOpOrEd = true;
        print(
            "[PLAYER] Auto skipping OP from ${dataProvider.state.opSkip!.start}s to ${dataProvider.state.opSkip!.end}s");
        playerProvider
            .fastForward(dataProvider.state.opSkip!.end - currentPositionInSeconds + 1)
            .then((_) => _isSkippingOpOrEd = false);
      } else if (isAtEd) {
        _isSkippingOpOrEd = true;
        print(
            "[PLAYER] Auto skipping ED from ${dataProvider.state.edSkip!.start}s to ${dataProvider.state.edSkip!.end}s");
        playerProvider
            .fastForward(dataProvider.state.edSkip!.end - currentPositionInSeconds)
            .then((_) => _isSkippingOpOrEd = false);
      }
    }
  }

  // Mutex to avoid multiple skips at once
  bool _isSkippingOpOrEd = false;

  void hideControlsOnTimeout(PlayerDataProvider dp, PlayerProvider pp, {int timeoutSeconds = 5}) {
    if (_controlsTimer == null && (controller.isPlaying ?? false)) {
      _controlsTimer = Timer(Duration(seconds: timeoutSeconds), () {
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
  final int doubleTapThreshold = 300; // in ms
  bool _waitingForSecondTap = false;

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

    _animTimer = Timer(Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showRewindAnim = false;
          _showForwardAnim = false;
        });
      }
    });
  }

  void _handleTap() {
    // New Logic Baby!
    if (_waitingForSecondTap) {
      // event where the 2nd tap is detected
      _waitingForSecondTap = false;
      _tapTimer?.cancel();
      _handleDoubleTap();
      return;
    }

    _handleSingleTap();
    _waitingForSecondTap = true;
    _tapTimer = Timer(Duration(milliseconds: doubleTapThreshold), () {
      // after threshold time, if no 2nd tap, treat it as succesful single tap
      if (mounted) {
        setState(() {
          _waitingForSecondTap = false;
        });
      }
    });

    // if (_tapTimer != null && _tapTimer!.isActive) {
    //   // Double tap
    //   _tapTimer!.cancel();
    //   _handleDoubleTap();
    // } else {
    //   // Single tap
    //   _tapTimer = Timer(Duration(milliseconds: doubleTapThreshold), () {
    //     _handleSingleTap();
    //   });
    // }
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
    if (context.read<PlayerProvider>().state.pip) return;
    final themeProvider = context.read<AppProvider>();
    themeProvider.setFullScreen(!themeProvider.isFullScreen);
  }

  bool hidePointer = false;

  // for tap gesures
  bool lTapped = false, rTapped = false;

  bool spedUp = false;

  int skipCount = 0;

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<PlayerProvider>();
    final playerDataProvider = context.watch<PlayerDataProvider>();

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        // save the last watched duration
        if (isInitiated && (controller.duration ?? 0) > 0) {
          final pos = (controller.position ?? 0).toDouble();
          final dur = controller.duration!.toDouble();
          double watchPercentage = (dur <= 0) ? 0.0 : (pos / dur);
          watchPercentage = watchPercentage.clamp(0.0, 1.0);
          await saveAnimeSpecificPreference(
            playerDataProvider.showId.toString(),
            AnimeSpecificPreference(
              lastWatchDuration: {playerDataProvider.state.currentEpIndex + 1: watchPercentage * 100},
            ),
          );
        }
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
              // show controls on mouse movement
              playerProvider.toggleControlsVisibility(action: true);
              hideControlsOnTimeout(playerDataProvider, playerProvider, timeoutSeconds: 2);

              // Hide the pointer when controls arent visible and mouse is unmoved for 3 seconds
              // if (playerProvider.state.controlsVisible) return;
              if (hidePointer) {
                setState(() {
                  hidePointer = false;
                });
              }
              pointerHideTimer?.cancel();
              pointerHideTimer = Timer(Duration(seconds: 3), () {
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
                onLongPressStart: (details) {
                  if (playerProvider.state.playerState == PlayerState.playing) {
                    spedUp = true;

                    // increase speed, Dont allow the max values >10x
                    final currSpeed = playerProvider.state.speed;
                    if (currSpeed >= 5) return;
                    playerProvider.setSpeed(currSpeed * 2);
                  } else {
                    return;
                  }
                },
                onLongPressEnd: (details) {
                  // reset only if speed was increased
                  if (!spedUp) return;
                  spedUp = false;
                  // reset speed
                  playerProvider.setSpeed(playerProvider.state.speed / 2);
                  print("Reduced speed to: ${playerProvider.state.speed}x");
                },
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
                                IgnorePointer(ignoring: !playerProvider.state.controlsVisible, child: Controls()),
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
                          flex: 2,
                          child: DoubleTapDectector(
                            behavior: HitTestBehavior.translucent,
                            onDoubleTap: () {
                              // windows shouldnt be having double tap to skip functionality
                              if (playerDataProvider.state.controlsLocked || Platform.isWindows) return;
                              if (currentUserSettings?.doubleTapToSkip ?? true) {
                                playerProvider.fastForward(-(currentUserSettings?.skipDuration ?? 10));
                                if (!_showRewindAnim) skipCount = 0;
                                _showFastForwardAnim(false);
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: Container(),
                          flex: 1,
                        ),
                        Expanded(
                          flex: 2,
                          child: DoubleTapDectector(
                            behavior: HitTestBehavior.translucent,
                            onDoubleTap: () {
                              // windows shouldnt be having double tap to skip functionality
                              if (playerDataProvider.state.controlsLocked || Platform.isWindows) return;
                              if (currentUserSettings?.doubleTapToSkip ?? true) {
                                playerProvider.fastForward(currentUserSettings?.skipDuration ?? 10);
                                if (!_showForwardAnim) skipCount = 0;
                                _showFastForwardAnim(true);
                              }
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
                duration: Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                opacity: _showRewindAnim ? 1 : 0,
                child: Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    // color: appTheme.backgroundSubColor.withAlpha(200),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    "- ${(currentUserSettings?.skipDuration ?? 10) * skipCount}s",
                    style: TextStyle(
                      fontFamily: "Rubik",
                      fontSize: 23,
                    ),
                  ),
                ),
              ),
              AnimatedOpacity(
                duration: Duration(milliseconds: 400),
                opacity: _showForwardAnim ? 1 : 0,
                curve: Curves.easeInOut,
                child: Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    // color: appTheme.backgroundSubColor.withAlpha(200),
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
      if(!widget.localSource)
        print("[PLAYER] SAVED WATCH DURATION");
      controller.removeListener(_listener);
      controller.dispose();
      _controlsTimer?.cancel();
      _tapTimer?.cancel();
    }

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
