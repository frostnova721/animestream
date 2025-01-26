import 'dart:async';
import 'dart:io';

import 'package:animestream/core/anime/providers/gojo.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/commons/types.dart';
import 'package:animestream/core/data/watching.dart';
import 'package:animestream/ui/models/bottomSheets/customControlsSheet.dart';
import 'package:animestream/ui/models/watchPageUtil.dart';
import 'package:animestream/ui/models/widgets/customControls.dart';
import 'package:animestream/ui/models/playerUtils.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/models/sources.dart';
import 'package:animestream/ui/models/widgets/subtitles.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:animestream/ui/pages/settingPages/player.dart';
import 'package:av_media_player/index.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:better_player/better_player.dart';

class Watch extends StatefulWidget {
  final String selectedSource;
  final WatchPageInfo info;
  final List<String> episodes;
  const Watch({
    super.key,
    required this.selectedSource,
    required this.info,
    required this.episodes,
  });

  @override
  State<Watch> createState() => _WatchState();
}

class _WatchState extends State<Watch> with TickerProviderStateMixin {
  // late BetterPlayerController controller;
  late VideoController controller;

  Timer? _controlsTimer;

  String currentQualityLink = '';
  String selectedQuality = (currentUserSettings?.preferredQuality?.replaceAll("p", "") ?? "720");
  // String? subs;

  List<String> epLinks = [];
  List<Map<String, String>> qualities = [];

  late WatchPageInfo info;

  int currentEpIndex = 0;
  int currentViewMode = 0;

  final List<Map<String, dynamic>> viewModes = [
    {
      'icon': Icons.fullscreen,
      'desc': "fit",
      'value': BoxFit.contain,
    },
    {
      'icon': Icons.zoom_out_map_rounded,
      'desc': "filled",
      'value': BoxFit.fill,
    },
    {
      'icon': Icons.crop_outlined,
      'desc': "cropped",
      'value': BoxFit.cover,
    },
  ];

  bool _isTimerActive = false;
  bool controlsLocked = false;
  bool _visible = true; //inverse of this means that the controls is being ignored
  bool initialised = false;
  bool showSubs = false;

  //1x speed initially
  double playBackSpeed = 1;
  List<double> playBackSpeeds = [
    1,
    1.25,
    1.5,
    1.75,
    2,
    if (currentUserSettings?.enableSuperSpeeds ?? false) ...[4, 5, 8, 10]
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    info = widget.info;
    currentEpIndex = info.episodeNumber - 1;
    epLinks = widget.episodes;

    showSubs = info.streamInfo.subtitle != null;

    final config = BetterPlayerConfiguration(
        aspectRatio: 16 / 9,
        fit: BoxFit.contain,
        expandToFill: true,
        autoPlay: true,
        autoDispose: true,
        controlsConfiguration: BetterPlayerControlsConfiguration(showControls: false));

    // controller = BetterPlayerController(config);
    controller = Platform.isWindows ?  AvPlayerWrapper() : BetterPlayerWrapper();

    //try to get the qualities. play with the default link if qualities arent available
    try {
      if (!info.streamInfo.isM3u8)
        playVideo(info.streamInfo.link);
      else
        getQualities().then((val) {
          print(qualities);
          print("${info.streamInfo.subtitle ?? "no subs!"}");
          final preferredOne = qualities.where((item) => item['quality'] == selectedQuality).toList();
          changeQuality(preferredOne.isNotEmpty ? preferredOne[0]['link']! : qualities[0]['link']!, null);
        });
    } catch (err) {
      print(err.toString());
      if (currentUserSettings?.showErrors ?? false) {
        floatingSnackBar(context, err.toString());
      }
      playVideo(info.streamInfo.link);
    }
  }

  void refreshPlayerValues() {
    playBackSpeeds = [
      1,
      1.25,
      1.5,
      1.75,
      2,
      if (currentUserSettings?.enableSuperSpeeds ?? false) ...[4, 5, 8, 10]
    ];
  }

  Future<void> playVideo(String url) async {
    // await controller.setupDataSource(dataSourceConfig(url, headers: info.streamInfo.customHeaders));
    await controller.initiateVideo(url, headers: headers);
    setState(() {
      initialised = true;
    });
  }

  bool isControlsLocked() {
    return controlsLocked;
  }

  Future<void> refreshPage(int episodeIndex, Stream streamInfo) async {
    print('refreshing $episodeIndex');
    info.streamInfo = streamInfo;
    qualities = [];
    bool shouldUpdate = currentEpIndex < episodeIndex;
    setState(() {
      info.episodeNumber = episodeIndex + 1;
      currentEpIndex = episodeIndex;
    });
    await getQualities();
    if (shouldUpdate)
      await updateWatching(
        widget.info.id,
        info.animeTitle,
        episodeIndex,
        widget.info.altDatabases,
      );
  }

  Future<void> updateWatchProgress(int episodeIndex) async {
    await updateWatching(
      widget.info.id,
      info.animeTitle,
      episodeIndex + 1,
      widget.info.altDatabases,
    );
  }

  Future getEpisodeSources(String epLink, Function(List<Stream>, bool) cb) async {
    await getStreams(widget.selectedSource, epLink, cb);
  }

  Future<void> getQualities({String? link}) async {
    final list = await generateQualitiesForMultiQuality(link ?? info.streamInfo.link,
        customHeaders: info.streamInfo.customHeaders);
    if (mounted)
      setState(() {
        qualities = list;
      });
  }

  /** to play the next or prev episode */
  Future<void> playAnotherEpisode(String link, {bool preserveProgress = false}) async {
    try {
      toggleControls(true); //show the controls ig
      await controller.pause();
      await getQualities(link: link);
      final preferredQuality = qualities.where((item) => item['quality'] == selectedQuality).toList();
      print(preferredQuality[0]['link']);
      await changeQuality(
        preferredQuality[0]['link']!,
        // preserveProgress ? controller.videoPlayerController!.value.position.inSeconds : null,
        preserveProgress ? (controller.position ?? 0) * 100 : null,
      );
    } catch (err) {
      print(err);
      await playVideo(link);
    }
  }

  Future<void> changeQuality(String link, int? currentTime) async {
    if (currentQualityLink != link) {
      await playVideo(link);
      if (currentTime != null) controller.seekTo(Duration(seconds: currentTime));
      currentQualityLink = link;
    }
  }

  void toggleControls(bool value) async {
    if (_controlsTimer != null) {
      _controlsTimer?.cancel();
      _controlsTimer = null;
    }
    await Future.delayed(
      Duration(milliseconds: 100),
    );
    setState(() {
      _visible = value;
      _isTimerActive = false;
    });
  }

  void hideControlsOnTimeout() {
    if (_visible && !_isTimerActive) {
      if (_controlsTimer != null) {
        _controlsTimer!.cancel();
        _controlsTimer = null;
      }
      _isTimerActive = true;
      print("called hideontimeout: $_visible");
      _controlsTimer = Timer(Duration(seconds: 5), () {
        if (mounted && (controller.isPlaying ?? false)) {
          toggleControls(false);
        }
        _isTimerActive = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        toggleControls(!_visible);
        hideControlsOnTimeout();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Player(controller),
            // Platform.isWindows
            //     ? Stack(
            //         children: [
            //           AvMediaView(
            //             initSource: info.streamInfo.link,
            //             initAutoPlay: true,
            //             onCreated: (p) {},
            //           ),
            //           IconButton(
            //               onPressed: () {
            //                 Navigator.of(context).pop();
            //               },
            //               icon: Icon(Icons.no_backpack_sharp)),
            //         ],
            //       )
            //     : BetterPlayer(controller: controller),
            if (info.streamInfo.subtitle != null
                // && controller.videoPlayerController != null
                &&
                showSubs)
              SubViewer(
                  // controller: controller.videoPlayerController!,
                  controller: controller,
                  format: info.streamInfo.subtitleFormat ?? SubtitleFormat.ASS,
                  subtitleSource: info.streamInfo.subtitle!),
            AnimatedOpacity(
              opacity: _visible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 150),
              child: Stack(
                children: [
                  IgnorePointer(ignoring: true, child: overlay()),
                  IgnorePointer(
                    ignoring: !_visible,
                    child: initialised
                        // ? Container()
                        ? Controls(
                            controller: controller,
                            bottomControls: bottomControls(),
                            topControls: topControls(),
                            episode: {
                              'getEpisodeSources': getEpisodeSources,
                              'epLinks': epLinks,
                              'currentEpIndex': currentEpIndex,
                            },
                            refreshPage: refreshPage,
                            updateWatchProgress: updateWatchProgress,
                            isControlsLocked: isControlsLocked,
                            hideControlsOnTimeout: hideControlsOnTimeout,
                            playAnotherEpisode: playAnotherEpisode,
                            preferredServer: info.streamInfo.server,
                            isControlsVisible: _visible,
                            toggleControls: toggleControls,
                          )
                        : Container(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Expanded topControls() {
    return Expanded(
      child: Container(
        alignment: Alignment.topCenter,
        child: Container(
          height: 50,
          child: Row(
            children: [
              if (!controlsLocked)
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
              Expanded(
                child: controlsLocked
                    ? Container()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.only(left: 20, top: 5),
                            alignment: Alignment.topLeft,
                            child: Text("Episode ${info.episodeNumber}",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'NotoSans',
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                )),
                          ),
                          Container(
                            padding: const EdgeInsets.only(left: 20),
                            alignment: Alignment.topLeft,
                            child: Text(
                              "${info.animeTitle}",
                              style: TextStyle(
                                color: Color.fromARGB(255, 190, 190, 190),
                                fontFamily: 'NotoSans',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                overflow: TextOverflow.ellipsis,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
              ),
              if (kDebugMode && !controlsLocked)
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        backgroundColor: Colors.black,
                        contentTextStyle: TextStyle(color: Colors.white),
                        title: Text("Stream info", style: TextStyle(color: appTheme.accentColor)),
                        content: Text(
                          //Resolution: ${qualities.where((element) => element['link'] == currentQualityLink).toList()[0]?? ['resolution'] ?? ''}   idk
                          "Aspect Ratio: 16:9 (probably) \nServer: ${widget.selectedSource} \nSource: ${info.streamInfo.server} ${info.streamInfo.backup ? "\(backup\)" : ''}",
                        ),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.info_rounded,
                    color: Colors.white,
                  ),
                ),
              if (!controlsLocked)
                IconButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerSetting()))
                        .then((val) => refreshPlayerValues());
                  },
                  tooltip: "Player settings",
                  icon: Icon(
                    Icons.video_settings_rounded,
                    color: Colors.white,
                  ),
                ),
              IconButton(
                onPressed: () {
                  setState(() {
                    controlsLocked = !controlsLocked;
                  });
                },
                icon: Icon(
                  !controlsLocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //idea: use this in customControls file!
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

  Container bottomControls() {
    return controlsLocked
        ? Container()
        : Container(
            height: 40,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        showModalBottomSheet(
                          isScrollControlled: true,
                          context: context,
                          backgroundColor: appTheme.modalSheetBackgroundColor,
                          showDragHandle: false,
                          barrierColor: Color.fromARGB(17, 255, 255, 255),
                          builder: (BuildContext context) {
                            return Container(
                              width: 400,
                              padding: EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Text(
                                      "Choose Quality",
                                      style:
                                          TextStyle(color: appTheme.textMainColor, fontFamily: "Rubik", fontSize: 20),
                                    ),
                                  ),
                                  ListView.builder(
                                    itemCount: qualities.length,
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemBuilder: (BuildContext context, index) {
                                      return Container(
                                        padding: EdgeInsets.only(left: 25, right: 25),
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            final src = qualities[index]['link']!;
                                            selectedQuality = qualities[index]['quality'] ?? '720';
                                            changeQuality(src, controller.position ?? 0 * 100);
                                            Navigator.pop(context);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              // side: BorderSide(color: Colors.white)
                                            ),
                                            backgroundColor: qualities[index]['link'] == currentQualityLink
                                                ? appTheme.accentColor
                                                : appTheme.backgroundSubColor,
                                          ),
                                          child: Text(
                                            "${qualities[index]['quality']}${qualities[index]['quality'] == 'default' ? "" : 'p'}",
                                            style: TextStyle(
                                              color: qualities[index]['link'] == currentQualityLink
                                                  ? Colors.black
                                                  : appTheme.accentColor,
                                              fontFamily: "Poppins",
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      tooltip: "qualities",
                      icon: Icon(
                        Icons.high_quality_rounded,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        showModalBottomSheet(
                          isScrollControlled: true,
                          context: context,
                          backgroundColor: appTheme.modalSheetBackgroundColor,
                          builder: (context) => CustomControlsBottomSheet(
                              getEpisodeSources: getEpisodeSources,
                              currentSources: [],
                              playVideo: playAnotherEpisode,
                              next: true,
                              epLinks: epLinks,
                              currentEpIndex: currentEpIndex - 1,
                              refreshPage: refreshPage,
                              preserveProgress: true,
                              updateCurrentEpIndex: (int) {}),
                        );
                      },
                      tooltip: "servers",
                      icon: Icon(
                        Icons.source_rounded,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        showModalBottomSheet(
                          isScrollControlled: true,
                          backgroundColor: appTheme.modalSheetBackgroundColor,
                          context: context,
                          builder: (context) => Container(
                            padding: EdgeInsets.only(left: 20, right: 20, top: 15),
                            height: MediaQuery.of(context).size.height - 80,
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Text(
                                    "Select Episode",
                                    style: textStyle().copyWith(fontSize: 23),
                                  ),
                                ),
                                Container(
                                  height: MediaQuery.of(context).size.height - 150,
                                  child: GridView.builder(
                                    itemCount: epLinks.length,
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2, childAspectRatio: 4),
                                    shrinkWrap: true,
                                    padding: EdgeInsets.only(left: 10, right: 10),
                                    itemBuilder: (context, index) {
                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.pop(context);
                                          if (index == currentEpIndex) return;
                                          sheet2(index, index > currentEpIndex);
                                        },
                                        child: Container(
                                          margin: EdgeInsets.all(5),
                                          height: 50,
                                          decoration: BoxDecoration(
                                              color: index == currentEpIndex
                                                  ? appTheme.accentColor
                                                  : appTheme.backgroundSubColor,
                                              borderRadius: BorderRadius.circular(12)),
                                          alignment: Alignment.center,
                                          child: Text(
                                            "Episode ${index + 1}",
                                            style: TextStyle(
                                              color: index == currentEpIndex
                                                  ? appTheme.backgroundColor
                                                  : appTheme.textMainColor,
                                              fontFamily: "Rubik",
                                              fontSize: 20,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      tooltip: "Episode list",
                      icon: Icon(
                        Icons.view_list_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                //right side
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return playBackSpeedDialog();
                          },
                        );
                      },
                      tooltip: "Playback speed",
                      icon: Icon(
                        Icons.speed_rounded,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                        onPressed: () {
                          setState(() {
                            showSubs = !showSubs;
                          });
                        },
                        tooltip: "Subtitles",
                        icon: Icon(
                          !showSubs ? Icons.subtitles_outlined : Icons.subtitles_rounded,
                          color: Colors.white,
                        )),
                    IconButton(
                      onPressed: () {
                        currentViewMode = (currentViewMode + 1) % 3;
                        // controller.setOverriddenFit(viewModes[currentViewMode]['value']);
                        setState(() {});
                      },
                      icon: Icon(viewModes[currentViewMode]['icon']),
                      tooltip: viewModes[currentViewMode]['desc'],
                      color: Colors.white,
                    )
                  ],
                )
              ],
            ),
          );
  }

  Widget playBackSpeedDialog() {
    return Container(
      height: MediaQuery.of(context).size.height / 2,
      child: AlertDialog(
          content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              "Speed",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: "Rubik"),
            ),
          ),
          StatefulBuilder(
            builder: (context, setState) => Container(
              height: 230,
              width: 250,
              child: ListView.builder(
                itemCount: playBackSpeeds.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return Container(
                    margin: EdgeInsets.only(bottom: 5),
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: appTheme.backgroundSubColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            playBackSpeed = playBackSpeeds[index];
                          });
                          controller.setSpeed(playBackSpeed);
                        },
                        child: Row(
                          children: [
                            Radio<double>(
                              value: playBackSpeeds[index],
                              groupValue: playBackSpeed,
                              onChanged: (val) {
                                setState(() {
                                  playBackSpeed = val ?? 1.0;
                                });
                                controller.setSpeed(playBackSpeed);
                              },
                            ),
                            Text(playBackSpeeds[index].toString() + "x"),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 5),
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "close",
                style: TextStyle(fontSize: 16),
              ),
            ),
          )
        ],
      )),
    );
  }

  //ignore the random name
  void sheet2(
    int index,
    bool next,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: appTheme.modalSheetBackgroundColor,
      builder: (context) => CustomControlsBottomSheet(
        getEpisodeSources: getEpisodeSources,
        currentSources: [],
        playVideo: playAnotherEpisode,
        next: next,
        customIndex: index,
        epLinks: epLinks,
        currentEpIndex: currentEpIndex,
        refreshPage: refreshPage,
        updateCurrentEpIndex: (int updatedIndex) {
          currentEpIndex = updatedIndex;
        },
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
    controller.dispose();
    _controlsTimer?.cancel();
    super.dispose();
  }
}
