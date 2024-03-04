import 'package:animestream/core/data/settings.dart';
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
  final Future<void> Function(int, dynamic) refreshPage;
  final Future<void> Function(int) updateWatchProgress;

  const Controls({
    super.key,
    required this.controller,
    required this.bottomControls,
    required this.topControls,
    required this.episode,
    required this.refreshPage,
    required this.updateWatchProgress,
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
  bool calledAutoNext = false;

  @override
  void initState() {
    super.initState();

    Wakelock.enable();

    currentEpIndex = widget.episode['currentEpIndex'];

    _betterPlayerController = widget.controller;
    _controller = widget.controller.videoPlayerController;

    assignSettings();

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
      final currentByTotal = _controller!.value.position.inSeconds /
          (_controller!.value.duration?.inSeconds ?? 1);
      if (currentByTotal * 100 >= 75 && !preloadStarted) {
        preloadNextEpisode();
        widget.updateWatchProgress(currentEpIndex + 1);
      }
      if (currentByTotal == 1 && calledAutoNext) {
        //change 0 to last selected stream
        calledAutoNext = true;
        if (preloadedSources.isNotEmpty) {
          playVideo(preloadedSources[0].link);
          currentEpIndex = currentEpIndex + 1;
          widget.refreshPage(currentEpIndex, preloadedSources[0]);
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
                );
              });
        }
      }
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
  late int skipDuration;
  int megaSkipDuration = 85;

  Future<void> assignSettings() async {
    final settings = await Settings().getSettings();
    setState(() {
      skipDuration = settings.skipDuration;
    });
  }

  Future preloadNextEpisode() async {
    if (currentEpIndex + 1 > widget.episode['epLinks'].length) {
      return;
    }
    preloadStarted = true;
    preloadedSources = [];
    final index = currentEpIndex + 1;
    List srcs = [];
    await widget.episode['getEpisodeSources'](widget.episode['epLinks'][index],
        (list, finished) {
      srcs = srcs + list;
      if (finished) {
        preloadedSources = srcs;
      }
    });
  }

  Future<dynamic> playVideo(String url) async {
    preloadedSources = [];
    preloadStarted = false;
    calledAutoNext = false;
    _betterPlayerController!.setupDataSource(
      BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        url,
        bufferingConfiguration: BetterPlayerBufferingConfiguration(
          maxBufferMs: 40000,
        ),
      ),
    );
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
                                  if (currentEpIndex == 0)
                                    return floatingSnackBar(context,
                                        "Already on the first episode");
                                  showModalBottomSheet(
                                      showDragHandle: true,
                                      backgroundColor: Color(0xff121212),
                                      context: context,
                                      builder: (BuildContext context) {
                                        return CustomControlsBottomSheet(
                                          getEpisodeSources: widget
                                              .episode['getEpisodeSources'],
                                          currentSources: currentSources,
                                          currentEpIndex: currentEpIndex,
                                          playVideo: playVideo,
                                          next: false,
                                          refreshPage: widget.refreshPage,
                                          epLinks: widget.episode['epLinks'],
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
                            InkWell(
                              onTap: () {
                                fastForward(-skipDuration);
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
                                fastForward(skipDuration);
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
                                  if (currentEpIndex + 1 ==
                                      widget.episode['epLinks'].length)
                                    return floatingSnackBar(context,
                                        "You are already in the final episode!");
                                  if (preloadedSources.isNotEmpty) {
                                    print("from preload");

                                    await playVideo(preloadedSources[0].link);
                                    currentEpIndex = currentEpIndex + 1;
                                    widget.refreshPage(
                                        currentEpIndex, preloadedSources[0]);
                                  } else
                                    showModalBottomSheet(
                                      showDragHandle: true,
                                      backgroundColor: Color(0xff121212),
                                      context: context,
                                      builder: (BuildContext context) {
                                        return CustomControlsBottomSheet(
                                          getEpisodeSources: widget
                                              .episode['getEpisodeSources'],
                                          currentSources: currentSources,
                                          currentEpIndex: currentEpIndex,
                                          playVideo: playVideo,
                                          next: true,
                                          refreshPage: widget.refreshPage,
                                          epLinks: widget.episode['epLinks'],
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
                          ],
                        ),
                      ),
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
                              ElevatedButton(
                                  onPressed: () {
                                    fastForward(megaSkipDuration);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Color.fromARGB(68, 0, 0, 0),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        side: BorderSide(color: themeColor)),
                                  ),
                                  child: Container(
                                    height: 50,
                                    child: Row(
                                      children: [
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(right: 5),
                                          child: Text(
                                            "+$megaSkipDuration",
                                            style: TextStyle(
                                                color: textMainColor,
                                                fontFamily: "Rubik",
                                                fontSize: 17),
                                          ),
                                        ),
                                        Icon(
                                          Icons.fast_forward_rounded,
                                          color: textMainColor,
                                        )
                                      ],
                                    ),
                                  )),
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
}

class CustomControlsBottomSheet extends StatefulWidget {
  final Function(String, Function(List<dynamic>, bool)) getEpisodeSources;
  final List<dynamic> currentSources;
  final Function playVideo;
  final bool next;
  final int currentEpIndex;
  final List<String> epLinks;
  final Function refreshPage;
  const CustomControlsBottomSheet({
    super.key,
    required this.getEpisodeSources,
    required this.currentSources,
    required this.playVideo,
    required this.next,
    required this.epLinks,
    required this.currentEpIndex,
    required this.refreshPage,
  });

  @override
  State<CustomControlsBottomSheet> createState() =>
      CustomControls_BottomSheetState();
}

class CustomControls_BottomSheetState extends State<CustomControlsBottomSheet> {
  List currentSources = [];
  int currentEpIndex = 0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    currentEpIndex = widget.currentEpIndex;
    currentSources = widget.currentSources;
    getSources(widget.next);
  }

  Future getSources(bool nextEpisode) async {
    if ((currentEpIndex == 0 && !nextEpisode) ||
        (currentEpIndex + 1 > widget.epLinks.length && nextEpisode)) {
      throw new Exception("Index too low or too high. Item not found!");
    }
    currentSources = [];
    final index = nextEpisode ? currentEpIndex + 1 : currentEpIndex - 1;
    final srcs =
        await widget.getEpisodeSources(widget.epLinks[index], (list, finished) {
      if (mounted)
        setState(() {
          if (finished) _isLoading = false;
          currentSources = currentSources + list;
        });
    });
    if (mounted)
      setState(() {
        currentSources = srcs;
      });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.only(left: 30, right: 30, top: 10, bottom: 20),
        child: currentSources.length > 0
            ? _isLoading
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _list(),
                      Center(
                        child: Container(
                          height: 100,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: themeColor,
                            ),
                          ),
                        ),
                      )
                    ],
                  )
                : _list()
            : Container(
                height: 100,
                child: Center(
                  child: CircularProgressIndicator(
                    color: themeColor,
                  ),
                ),
              ),
      ),
    );
  }

  ListView _list() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: currentSources.length,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.only(top: 15),
          decoration: BoxDecoration(
            color: Color.fromARGB(97, 190, 175, 255),
            borderRadius: BorderRadius.circular(20),
          ),
          child: ElevatedButton(
            onPressed: () async {
              await widget.playVideo(currentSources[index].link);
              currentEpIndex =
                  widget.next ? currentEpIndex + 1 : currentEpIndex - 1;
              widget.refreshPage(currentEpIndex, currentSources[index]);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(68, 190, 175, 255),
              padding: EdgeInsets.only(top: 5, bottom: 5, left: 20, right: 20),
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
                      currentSources[index].server,
                      style: TextStyle(
                        fontFamily: "NotoSans",
                        fontSize: 17,
                        color: themeColor,
                      ),
                    ),
                    if (currentSources[index].backup)
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
                    currentSources[index].quality,
                    style: TextStyle(color: Colors.white, fontFamily: "Rubik"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
