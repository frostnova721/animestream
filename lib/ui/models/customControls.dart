import 'dart:async';

import 'package:animestream/core/data/settings.dart';
import 'package:animestream/ui/models/bottomSheets/customControlsSheet.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';
import 'package:better_player/better_player.dart';
import 'package:better_player/src/video_player/video_player.dart';
import 'package:better_player/src/controls/better_player_material_progress_bar.dart';
import 'package:wakelock/wakelock.dart';
import 'package:animestream/core/commons/types.dart';

class Controls extends StatefulWidget {
  final BetterPlayerController controller;
  final Widget bottomControls;
  final Widget topControls;
  final Map<String, dynamic> episode;
  final Future<void> Function(int, dynamic) refreshPage;
  final Future<void> Function(int) updateWatchProgress;
  final bool Function() isControlsLocked;
  final void Function() hideControlsOnTimeout;
  final Future<void> Function(String) playAnotherEpisode;
  final String preferredServer;
  final bool isControlsVisible;

  const Controls({
    super.key,
    required this.controller,
    required this.bottomControls,
    required this.topControls,
    required this.episode,
    required this.refreshPage,
    required this.updateWatchProgress,
    required this.isControlsLocked,
    required this.hideControlsOnTimeout,
    required this.playAnotherEpisode,
    required this.preferredServer,
    required this.isControlsVisible,
  });

  @override
  State<Controls> createState() => _ControlsState();
}

class _ControlsState extends State<Controls> {
  
  late VideoPlayerController _controller;

  bool startedLoadingNext = false;

  int currentEpIndex = 0;
  bool preloadStarted = false;
  bool calledAutoNext = true;

  @override
  void initState() {
    super.initState();

    Wakelock.enable();
    wakelockEnabled = true;
    debugPrint("wakelock enabled");

    currentEpIndex = widget.episode['currentEpIndex'];

    _controller = widget.controller.videoPlayerController!;

    finalEpisodeReached = currentEpIndex + 1 >= widget.episode['epLinks'].length;

    assignSettings();

    //this widget will only be open when the video is initialised. so to hide the controls, call it first
    widget.hideControlsOnTimeout();

    _controller.addListener(() async {

      //manage currentEpIndex and clear preloads if the index changed
      if(currentEpIndex != widget.episode['currentEpIndex']) {
        preloadedSources = [];
        preloadStarted = false;
        currentEpIndex = widget.episode['currentEpIndex'];
      }

      if(widget.isControlsVisible) {
        widget.hideControlsOnTimeout();
        // isVisible = false;
      }

      //managing the UI updation
      if (mounted)
        setState(() {
          int duration = _controller.value.duration?.inSeconds ?? 0;
          int val = _controller.value.position.inSeconds;
          playPause = _controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded;
          currentTime = getFormattedTime(val);
          maxTime = getFormattedTime(duration);
          buffering = _controller.value.isBuffering;
        });

        if(_controller.value.isPlaying && !wakelockEnabled) {
          Wakelock.enable();
          wakelockEnabled = true;
          debugPrint("wakelock enabled");
        } else if(!_controller.value.isPlaying && wakelockEnabled) {
          Wakelock.disable();
          wakelockEnabled = false;
          debugPrint("wakelock disabled");
        }

      final duration = _controller.value.duration?.inSeconds;
      final currentPosition = _controller.value.position.inSeconds;

      //set player postion to duration if greater than duration
      if (duration != null && currentPosition > duration) {
        _controller.seekTo(Duration(seconds: duration));
        await _controller.pause();
      }

      //play the loaded episode if equal to duration
      if (!finalEpisodeReached && (currentPosition == duration) && duration != null) {
        await playPreloadedEpisode();
      }

      final currentByTotal = _controller.value.position.inSeconds / (_controller.value.duration?.inSeconds ?? 0);
      if (currentByTotal * 100 >= 75 && !preloadStarted) {
        preloadNextEpisode();
        widget.updateWatchProgress(currentEpIndex);
      }
    });
  }

  List<Stream> currentSources = [];
  List<Stream> preloadedSources = [];

  IconData? playPause;

  String currentTime = "0:00";
  String maxTime = "0:00";

  int selectedQuality = 0;
  int? skipDuration;
  int? megaSkipDuration;

  bool buffering = false;
  // bool isVisible = true;
  bool finalEpisodeReached = false;
  bool wakelockEnabled = false;
  // bool linkProgressValueWithPlayer = true;

  Timer? timer;

  void skipToStart() async {
    print("skipping...");
    await _controller.seekTo(Duration.zero);
  }

  //probably redundant function. might remove later
  void updateCurrentEpIndex(int updatedIndex) {
    currentEpIndex = updatedIndex;
  }

  Future<void> assignSettings() async {
    final settings = await Settings().getSettings();
    setState(() {
      skipDuration = settings.skipDuration ?? 10;
      megaSkipDuration = settings.megaSkipDuration ?? 85;
    });
  }

  Future<void> playPreloadedEpisode() async {
    if (currentEpIndex + 1 >= widget.episode['epLinks'].length) {
      print("yes");
      return;
    }
    calledAutoNext = true;
    if (preloadedSources.isNotEmpty) {
      currentEpIndex = currentEpIndex + 1;
      final preferredServerLink = preloadedSources.where((source) => source.server == widget.preferredServer).toList();
      final src = preferredServerLink.length != 0 ? preferredServerLink[0] : preloadedSources[0];
      widget.refreshPage(currentEpIndex, src);
      await playVideo(src.link);
    } else {
      showModalBottomSheet(
        context: context,
        builder: (context) {
          return CustomControlsBottomSheet(
            getEpisodeSources: widget.episode['getEpisodeSources'],
            currentSources: currentSources,
            playVideo: playVideo,
            next: true,
            epLinks: widget.episode['epLinks'],
            currentEpIndex: currentEpIndex,
            refreshPage: widget.refreshPage,
            updateCurrentEpIndex: updateCurrentEpIndex,
          );
        },
      );
    }
  }

  Future preloadNextEpisode() async {
    if (currentEpIndex + 1 == widget.episode['epLinks'].length) {
      print("final ep");
      finalEpisodeReached = true;
      preloadStarted = true; //to make sure this funcion doesnt get called over and over again if the last ep is reached
      return;
    }
    preloadStarted = true;
    preloadedSources = [];
    final index = currentEpIndex + 1 == widget.episode['epLinks'].length ? null : currentEpIndex + 1;
    if (index == null) {
      print("On the final episode. No preloads available");
      return;
    }
    List<Stream> srcs = [];
    await widget.episode['getEpisodeSources'](widget.episode['epLinks'][index], (list, finished) {
      srcs = srcs + list;
      if (finished) {
        preloadedSources = srcs;
        print("PRELOAD FINISHED");
      }
    });
  }

  /**Play the video */
  Future<void> playVideo(String url, {bool preserveProgress = false}) async {
    preloadedSources = [];
    await widget.playAnotherEpisode(url);
    preloadStarted = false;
    calledAutoNext = false;
  }

  Future getEpisodeSources(bool nextEpisode) async {
    if ((currentEpIndex == 0 && !nextEpisode) ||
        (currentEpIndex + 1 > widget.episode['epLinks'].length && nextEpisode)) {
      throw new Exception("Index too low or too high. Item not found!");
    }
    currentSources = [];
    final index = nextEpisode ? currentEpIndex + 1 : currentEpIndex - 1;
    final srcs = await widget.episode['getEpisodeSources'](widget.episode['epLinks'][index]);
    if (mounted)
      setState(() {
        currentSources = srcs;
      });
  }

  String getFormattedTime(int timeInSeconds) {
    String formatTime(int val) {
      return val.toString().padLeft(2, '0');
    }

    int hours = timeInSeconds ~/ 3600;
    int minutes = (timeInSeconds % 3600) ~/ 60;
    int seconds = timeInSeconds % 60;

    String formattedHours = hours == 0 ? '' : formatTime(hours);
    String formattedMins = formatTime(minutes);
    String formattedSeconds = formatTime(seconds);

    return "${formattedHours.length > 0 ? "$formattedHours:" : ''}$formattedMins:$formattedSeconds";
  }

  void fastForward(int seekDuration) {
    if ((_controller.value.position.inSeconds + seekDuration) <= 0) {
      _controller.seekTo(Duration(seconds: 0));
    } else {
      if ((_controller.value.position.inSeconds + seekDuration) > _controller.value.duration!.inSeconds) {
        _controller.seekTo(Duration(seconds: _controller.value.duration!.inSeconds));
      }
      _controller.seekTo(Duration(seconds: _controller.value.position.inSeconds + seekDuration));
    }
  }

  @override
  void dispose() {
    super.dispose();
    Wakelock.disable();
  }

  @override
  Widget build(BuildContext context) {
    //wrap in orientation builder
    return OrientationBuilder(
      builder: (context, orientation) {
        double LRpadding = 30;
        if (orientation == Orientation.portrait) LRpadding = 10;
        return Padding(
          padding: EdgeInsets.only(top: 15, left: LRpadding, right: LRpadding, bottom: 5),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    widget.topControls,
                    Expanded(
                      child: widget.isControlsLocked() ? lockedCenterControls() : centerControls(context),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    currentTime,
                                    style: TextStyle(color: Colors.white, fontFamily: 'NunitoSans'),
                                  ),
                                  const Text(
                                    " / ",
                                    style: TextStyle(color: Colors.white, fontFamily: 'NunitoSans'),
                                  ),
                                  Text(
                                    maxTime,
                                    style: TextStyle(color: Colors.white, fontFamily: 'NunitoSans'),
                                  ),
                                ],
                              ),
                              if (megaSkipDuration != null) widget.isControlsLocked() ? Container() : megaSkipButton(),
                            ],
                          ),
                          Container(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: 20,
                              child: IgnorePointer(
                                ignoring: widget.isControlsLocked(),
                                child: Container(
                                  child: SliderTheme(
                                    data: SliderThemeData(
                                        trackHeight: 1.3,
                                        thumbColor: accentColor,
                                        activeTrackColor: accentColor,
                                        inactiveTrackColor: Color.fromARGB(255, 121, 121, 121),
                                        secondaryActiveTrackColor: Color.fromARGB(255, 167, 167, 167),
                                        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                                        trackShape: EdgeToEdgeTrackShape(),
                                        overlayShape: SliderComponentShape.noThumb),
                                    child: BetterPlayerMaterialVideoProgressBar(
                                      _controller,
                                      widget.controller,
                                      onDragStart: () {
                                        widget.controller.pause();
                                      },
                                      onDragEnd: () {
                                        widget.controller.play();
                                      },
                                      colors: BetterPlayerProgressColors(
                                        playedColor: accentColor,
                                        handleColor: widget.isControlsLocked() ? Colors.transparent : accentColor,
                                        bufferedColor: Color.fromARGB(255, 167, 167, 167),
                                        backgroundColor: Color.fromARGB(255, 94, 94, 94),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          widget.bottomControls
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  ElevatedButton megaSkipButton() {
    return ElevatedButton(
      onPressed: () {
        fastForward(megaSkipDuration!);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Color.fromARGB(68, 0, 0, 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: accentColor),
        ),
      ),
      child: Container(
        height: 50,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Text(
                "+$megaSkipDuration",
                style: TextStyle(
                  color: textMainColor,
                  fontFamily: "Rubik",
                  fontSize: 17,
                ),
              ),
            ),
            Icon(
              Icons.fast_forward_rounded,
              color: textMainColor,
            )
          ],
        ),
      ),
    );
  }

  Container lockedCenterControls() {
    return Container(
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (buffering)
            Container(
              width: 40,
              height: 40,
              child: Center(
                child: CircularProgressIndicator(
                  color: accentColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Container centerControls(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Padding(
          // padding: EdgeInsets.only(right: 35),
          // child:
          Material(
            color: Colors.transparent,
            child: Container(
              margin: EdgeInsets.only(right: 5),
              height: 65,
              width: 65,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  if (currentEpIndex == 0) return floatingSnackBar(context, "Already on the first episode");
                  showModalBottomSheet(
                      showDragHandle: true,
                      backgroundColor: Color(0xff121212),
                      context: context,
                      builder: (BuildContext context) {
                        return CustomControlsBottomSheet(
                          getEpisodeSources: widget.episode['getEpisodeSources'],
                          currentSources: currentSources,
                          currentEpIndex: currentEpIndex,
                          playVideo: playVideo,
                          next: false,
                          refreshPage: widget.refreshPage,
                          epLinks: widget.episode['epLinks'],
                          updateCurrentEpIndex: updateCurrentEpIndex,
                        );
                      });
                },
                child: Icon(
                  Icons.skip_previous_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
          // ),
          Material(
            color: Colors.transparent,
            child: Container(
              height: 65,
              width: 65,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  fastForward(skipDuration != null ? -skipDuration! : -10);
                },
                child: Icon(
                  Icons.fast_rewind_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
          Container(
            // padding: EdgeInsets.only(left: 35, right: 35),
            child: !buffering
                ? Material(
                    color: Colors.transparent,
                    child: Container(
                      margin: EdgeInsets.only(left: 5, right: 5),
                      height: 65,
                      width: 65,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          if (_controller.value.isPlaying) {
                            playPause = Icons.play_arrow_rounded;
                            _controller.pause();
                          } else {
                            playPause = Icons.pause_rounded;
                            _controller.play();
                          }
                          setState(() {});
                        },
                        child: Icon(
                          playPause,
                          color: Colors.white,
                          size: 45,
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: 65,
                    height: 65,
                    margin: EdgeInsets.only(left: 5, right: 5),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: accentColor,
                      ),
                    ),
                  ),
          ),
          Material(
            color: Colors.transparent,
            child: Container(
              height: 65,
              width: 65,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  fastForward(skipDuration ?? 10);
                },
                child: Icon(
                  Icons.fast_forward_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
          // Padding(
          // padding: EdgeInsets.only(left: 35),
          // child:
          Material(
            color: Colors.transparent,
            child: Container(
              margin: EdgeInsets.only(left: 5),
              height: 65,
              width: 65,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  //get next episode sources!
                  if (currentEpIndex + 1 == widget.episode['epLinks'].length)
                    return floatingSnackBar(context, "You are already in the final episode!");
                  if (preloadedSources.isNotEmpty) {
                    print("from preload");
                    final source = preloadedSources[0];
                    await playVideo(preloadedSources[0].link);
                    currentEpIndex += 1;
                    widget.refreshPage(currentEpIndex, source);
                    print(currentEpIndex);
                  } else
                    showModalBottomSheet(
                      showDragHandle: true,
                      backgroundColor: Color(0xff121212),
                      context: context,
                      builder: (BuildContext context) {
                        return CustomControlsBottomSheet(
                          getEpisodeSources: widget.episode['getEpisodeSources'],
                          currentSources: currentSources,
                          currentEpIndex: currentEpIndex,
                          playVideo: playVideo,
                          next: true,
                          refreshPage: widget.refreshPage,
                          epLinks: widget.episode['epLinks'],
                          updateCurrentEpIndex: updateCurrentEpIndex,
                        );
                      },
                    );
                },
                child: Icon(
                  Icons.skip_next_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
          // ),
        ],
      ),
    );
  }
}

class EdgeToEdgeTrackShape extends RoundedRectSliderTrackShape {
  // Override getPreferredRect to adjust the track's dimensions
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 2.0;
    final double trackWidth = parentBox.size.width;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    return Rect.fromLTWH(offset.dx, trackTop, trackWidth, trackHeight);
  }
}
