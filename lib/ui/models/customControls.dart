import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';
import 'package:better_player/better_player.dart';
import 'package:better_player/src/video_player/video_player.dart';
import 'package:better_player/src/controls/better_player_material_progress_bar.dart';
import 'package:wakelock/wakelock.dart';

class Controls extends StatefulWidget {
  final BetterPlayerController controller;
  final Widget bottomControls;
  final Widget topControls;
  final Map<String, dynamic> episode;
  final Function(int, dynamic) refreshPage;

  const Controls({
    super.key,
    required this.controller,
    required this.bottomControls,
    required this.topControls,
    required this.episode,
    required this.refreshPage,
  });

  @override
  State<Controls> createState() => _ControlsState();
}

class _ControlsState extends State<Controls> {
  BetterPlayerController? _betterPlayerController;
  VideoPlayerController? _controller;

  bool startedLoadingNext = false;

  int currentEpIndex = 0;
  bool preloadStarted = false;

  @override
  void initState() {
    super.initState();

    Wakelock.enable();

    currentEpIndex = widget.episode['currentEpIndex'];

    _betterPlayerController = widget.controller;
    _controller = widget.controller.videoPlayerController;

    _controller?.addListener(() {
      if (_controller!.value.position.inSeconds ==
          _controller!.value.duration?.inSeconds) {
        if (preloadedSources.isNotEmpty) {
          _betterPlayerController!.setupDataSource(
              BetterPlayerDataSource.network(preloadedSources[0].link));
        }
      }
      if (mounted)
        setState(() {
          int duration = _controller?.value.duration?.inSeconds ?? 0;
          int val = _controller?.value.position.inSeconds ?? 0;
          playPause = _betterPlayerController?.isPlaying() == true
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded;
          buffering = _controller!.value.isBuffering;
          currentTime = getFormattedTime(val);
          maxTime = getFormattedTime(duration);
        });
      if ((_controller!.value.position.inSeconds *
                  (_controller!.value.duration?.inSeconds ?? 0)) /
              100 >=
          75 && !preloadStarted) {
        preloadNextEpisode();
      }
      ;
    });
  }

  IconData? playPause;
  String currentTime = "0:00";
  String maxTime = "0:00";
  bool buffering = false;
  bool isVisible = true;
  int selectedQuality = 0;
  List currentSources = [];
  List preloadedSources = [];

  Future preloadNextEpisode() async {
    if ((currentEpIndex == 0) ||
        (currentEpIndex + 1 > widget.episode['epLinks'].length)) {
      return;
    }
    preloadedSources = [];
    final index = currentEpIndex + 1;
    final srcs = await widget
        .episode['getEpisodeSources'](widget.episode['epLinks'][index]);
    if (mounted) preloadedSources = srcs;
  }

  Future getEpisodeSources(bool nextEpisode) async {
    if ((currentEpIndex == 0 && !nextEpisode) ||
        (currentEpIndex + 1 > widget.episode['epLinks'].length &&
            nextEpisode)) {
      throw new Exception("Index too low or too high. Item not found!");
    }
    currentSources = [];
    final index = nextEpisode ? currentEpIndex + 1 : currentEpIndex - 1;
    final srcs = await widget
        .episode['getEpisodeSources'](widget.episode['epLinks'][index]);
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
    _controller!.seekTo(Duration(
        seconds: _controller!.value.position.inSeconds + seekDuration));
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
          padding: EdgeInsets.only(
              top: 20, left: LRpadding, right: LRpadding, bottom: 5),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    widget.topControls,
                    Expanded(
                      child: Container(
                        alignment: Alignment.center,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(right: 35),
                              child: InkWell(
                                onTap: () async {
                                  showModalBottomSheet(
                                    showDragHandle: true,
                                    backgroundColor: Color(0xff121212),
                                    context: context,
                                    builder: (BuildContext context) {
                                      return _streamButton(0, false);
                                    },
                                  );
                                  try {
                                    await getEpisodeSources(false);
                                    Navigator.of(context).pop();
                                    showModalBottomSheet(
                                      showDragHandle: true,
                                      backgroundColor:
                                          Color.fromARGB(255, 19, 19, 19),
                                      context: context,
                                      builder: (BuildContext context) {
                                        return _streamButton(
                                            currentEpIndex - 1, false);
                                      },
                                    );
                                  } on Exception catch (e) {
                                    Navigator.of(context).pop(context);
                                    print(e);
                                    floatingSnackBar(
                                        context, "Already on first episode!");
                                  }
                                },
                                child: Icon(
                                  Icons.skip_previous_rounded,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                fastForward(-10);
                              },
                              child: Icon(
                                Icons.fast_rewind_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.only(left: 35, right: 35),
                              width: 120,
                              child: !buffering
                                  ? InkWell(
                                      onTap: () {
                                        if (widget.controller.isPlaying()!) {
                                          playPause = Icons.play_arrow_rounded;
                                          widget.controller.pause();
                                          Wakelock.disable();
                                        } else {
                                          playPause = Icons.pause_rounded;
                                          widget.controller.play();
                                          Wakelock.enable();
                                        }
                                      },
                                      child: Icon(
                                        playPause,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                    )
                                  : Container(
                                      width: 40,
                                      height: 40,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: themeColor,
                                        ),
                                      ),
                                    ),
                            ),
                            InkWell(
                              onTap: () {
                                fastForward(10);
                              },
                              child: Icon(
                                Icons.fast_forward_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 35),
                              child: InkWell(
                                onTap: () async {
                                  //get next episode sources!

                                  showModalBottomSheet(
                                    showDragHandle: true,
                                    backgroundColor: Color(0xff121212),
                                    context: context,
                                    builder: (BuildContext context) {
                                      return _streamButton(0, true);
                                    },
                                  );
                                  try {
                                    await getEpisodeSources(true);
                                    Navigator.of(context).pop();
                                    showModalBottomSheet(
                                      showDragHandle: true,
                                      backgroundColor:
                                          Color.fromARGB(255, 19, 19, 19),
                                      context: context,
                                      builder: (BuildContext context) {
                                        return _streamButton(
                                            currentEpIndex + 1, true);
                                      },
                                    );
                                  } on Exception catch (e) {
                                    Navigator.of(context).pop(context);
                                    print(e);
                                    floatingSnackBar(
                                      context,
                                      "Already on the final available episode",
                                    );
                                  }
                                },
                                child: Icon(
                                  Icons.skip_next_rounded,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Text(
                                currentTime,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'NunitoSans'),
                              ),
                              const Text(
                                " / ",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'NunitoSans'),
                              ),
                              Text(
                                maxTime,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'NunitoSans'),
                              ),
                            ],
                          ),
                          Container(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: 20,
                              child: BetterPlayerMaterialVideoProgressBar(
                                _controller,
                                _betterPlayerController,
                                onDragStart: () {
                                  widget.controller.pause();
                                },
                                onDragEnd: () {
                                  widget.controller.play();
                                },
                                colors: BetterPlayerProgressColors(
                                  playedColor: themeColor,
                                  handleColor: themeColor,
                                  bufferedColor:
                                      const Color.fromARGB(255, 126, 126, 126),
                                  backgroundColor:
                                      Color.fromARGB(255, 63, 63, 63),
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

  Container _streamButton(int episode, bool next) {
    return Container(
      padding: EdgeInsets.only(top: 20, left: 25, right: 25, bottom: 30),
      child: currentSources.length > 0
          ? ListView.builder(
              shrinkWrap: true,
              itemCount: currentSources.length,
              itemBuilder: (context, i) {
                return Container(
                  margin: EdgeInsets.only(top: 15),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(97, 190, 175, 255),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      _betterPlayerController!.setupDataSource(
                          BetterPlayerDataSource.network(
                              currentSources[i].link));
                      currentEpIndex =
                          next ? currentEpIndex + 1 : currentEpIndex - 1;
                      widget.refreshPage(currentEpIndex, currentSources[i]);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(68, 190, 175, 255),
                      padding: EdgeInsets.only(
                          top: 10, bottom: 10, left: 20, right: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              currentSources[i].server,
                              style: TextStyle(
                                fontFamily: "NotoSans",
                                fontSize: 17,
                                color: themeColor,
                              ),
                            ),
                            if (currentSources[i].backup)
                              Text(
                                " • backup",
                                style: TextStyle(
                                  fontFamily: "NotoSans",
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              )
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: Text(
                            currentSources[i].quality,
                            style: TextStyle(
                                color: Colors.white, fontFamily: "Rubik"),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          : Container(
              height: 100,
              child: Center(
                child: CircularProgressIndicator(
                  color: themeColor,
                ),
              ),
            ),
    );
  }
}
