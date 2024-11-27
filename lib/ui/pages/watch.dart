import 'dart:async';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/types.dart';
import 'package:animestream/core/data/watching.dart';
import 'package:animestream/ui/models/bottomSheets/customControlsSheet.dart';
import 'package:animestream/ui/models/customControls.dart';
import 'package:animestream/ui/models/playerUtils.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/models/sources.dart';
import 'package:animestream/ui/models/subtitles.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:animestream/ui/pages/settingPages/player.dart';
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
  late BetterPlayerController controller;

  Timer? _controlsTimer;

  String currentQualityLink = '';
  String selectedQuality = (currentUserSettings?.preferredQuality?.replaceAll("p", "") ?? "720");

  List<String> epLinks = [];
  List qualities = [];

  late WatchPageInfo info;

  int currentEpIndex = 0;

  bool _isTimerActive = false;
  bool controlsLocked = false;
  bool _visible = true; //inverse of this means that the controls is being ignored
  bool initialised = false;
  bool showSubs = true;

  //1x speed initially
  double playBackSpeed = 1;
  List<double> playBackSpeeds = [1, 1.25, 1.5, 1.75, 2];

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

    final config = BetterPlayerConfiguration(
        aspectRatio: 16 / 9,
        fit: BoxFit.contain,
        expandToFill: true,
        autoPlay: true,
        autoDispose: true,
        controlsConfiguration: BetterPlayerControlsConfiguration(showControls: false));

    controller = BetterPlayerController(config);

    //try to get the qualities. play with the default link if qualities arent available
    try {
      getQualities().then((val) {
        print(qualities);
        print("${info.streamInfo.subtitle ?? "no subs!"}");
        final preferredOne = qualities.where((item) => item['quality'] == selectedQuality).toList();
        changeQuality(preferredOne.length > 0 ? preferredOne[0]['link'] : qualities[0]['link'], null);
      });
    } catch (err) {
      print(err.toString());
      if (currentUserSettings?.showErrors ?? false) {
        floatingSnackBar(context, err.toString());
      }
      playVideo(info.streamInfo.link);
    }
  }

  Future<void> playVideo(String url) async {
    await controller.setupDataSource(dataSourceConfig(url));
    setState(() {
      initialised = true;
    });
  }

  bool isControlsLocked() {
    return controlsLocked;
  }

  Future<void> refreshPage(int episodeIndex, dynamic streamInfo) async {
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
      );
  }

  Future<void> updateWatchProgress(int episodeIndex) async {
    await updateWatching(
      widget.info.id,
      info.animeTitle,
      episodeIndex + 1,
    );
  }

  Future getEpisodeSources(String epLink, Function(List<Stream>, bool) cb) async {
    await getStreams(widget.selectedSource, epLink, cb);
  }

  Future<void> getQualities({String? link}) async {
    final List list = await generateQualitiesForMultiQuality(link ?? info.streamInfo.link);
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
      await changeQuality(preferredQuality[0]['link'],
          preserveProgress ? controller.videoPlayerController!.value.position.inSeconds : null);
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
    if(_controlsTimer != null) {
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
        if (mounted && (controller.isPlaying() ?? false)) {
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
            BetterPlayer(controller: controller),
            if (info.streamInfo.subtitle != null && controller.videoPlayerController != null && showSubs)
              SubViewer(
                  controller: controller.videoPlayerController!,
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
                child: Column(
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
    return Container(
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
                                style: TextStyle(color: appTheme.textMainColor, fontFamily: "Rubik", fontSize: 20),
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
                                      final src = qualities[index]['link'];
                                      selectedQuality = qualities[index]['quality'] ?? 720;
                                      changeQuality(src, controller.videoPlayerController!.value.position.inSeconds);
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
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              "Select Episode",
                              style: textStyle().copyWith(fontSize: 23),
                            ),
                          ),
                          Container(
                            height: MediaQuery.of(context).size.height - 150,
                            child: ListView.builder(
                              itemCount: epLinks.length,
                              shrinkWrap: true,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                    if (index == currentEpIndex) return;
                                    sheet2(index, index > currentEpIndex);
                                  },
                                  child: Container(
                                    margin: EdgeInsets.only(top: 5, bottom: 5, left: 20, right: 20),
                                    padding: EdgeInsets.only(top: 10, bottom: 10, left: 20, right: 20),
                                    height: 50,
                                    decoration: BoxDecoration(
                                        color: index == currentEpIndex
                                            ? appTheme.accentColor
                                            : appTheme.backgroundSubColor,
                                        borderRadius: BorderRadius.circular(12)),
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "Episode ${index + 1}",
                                      style: TextStyle(
                                        color:
                                            index == currentEpIndex ? appTheme.backgroundColor : appTheme.textMainColor,
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
                  icon: Icon(
                    !showSubs ? Icons.subtitles_outlined : Icons.subtitles_rounded,
                    color: Colors.white,
                  )),
              IconButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerSetting()));
                },
                icon: Icon(
                  Icons.video_settings_rounded,
                  color: Colors.white,
                ),
              ),
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
                          controller.videoPlayerController?.setSpeed(playBackSpeed);
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
                                controller.videoPlayerController?.setSpeed(playBackSpeed);
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
