import 'package:animestream/ui/models/bottomSheets/customControlsSheet.dart';
import 'package:animestream/ui/models/providers/playerDataProvider.dart';
import 'package:animestream/ui/models/providers/playerProvider.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:animestream/ui/pages/settingPages/player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/ui/models/snackBar.dart';

class Controls extends StatefulWidget {
  const Controls({
    super.key,
  });

  @override
  State<Controls> createState() => _ControlsState();
}

class _ControlsState extends State<Controls> {
  bool startedLoadingNext = false;

  bool calledAutoNext = false;

  @override
  void initState() {
    super.initState();
  }

  int? skipDuration = currentUserSettings?.skipDuration ?? 10;
  int? megaSkipDuration = currentUserSettings?.megaSkipDuration ?? 85;

  @override
  void dispose() {
    super.dispose();
    WakelockPlus.disable();
    _fn.dispose();
  }

  final _fn = FocusNode();

  void _keyListenerEvent(KeyEvent event) {
    if (event is KeyUpEvent) return;
    print("Key pressed: ${event.logicalKey.keyLabel}");
    print(event);
    switch (event.logicalKey) {
      case LogicalKeyboardKey.mediaPlayPause:
      case LogicalKeyboardKey.mediaPause:
        provider.controller.pause();
        break;
      case LogicalKeyboardKey.mediaPlay:
        provider.controller.play();
        break;
      case LogicalKeyboardKey.mediaTrackNext:
        if (dataProvider.state.currentEpIndex + 1 ==
            dataProvider.epLinks.length) return;
        provider.playPreloadedEpisode(dataProvider);
        break;
      case LogicalKeyboardKey.mediaTrackPrevious:
        if (dataProvider.state.currentEpIndex == 0) return;
        showSheet(
            context,
            CustomControlsBottomSheet(
                index: dataProvider.state.currentEpIndex - 1,
                dataProvider: dataProvider,
                playerProvider: provider));
        break;
      case LogicalKeyboardKey.mediaFastForward:
        provider.fastForward(skipDuration ?? 10);
        break;
      case LogicalKeyboardKey.mediaRewind:
        provider.fastForward(-(skipDuration ?? 10));
        break;
      case LogicalKeyboardKey.select:
        {
          if (!provider.state.controlsVisible) {
            provider.toggleControlsVisibility();
          }
          break;
        }
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.arrowRight:
        {
          if (!provider.state.controlsVisible) {
            provider.toggleControlsVisibility();
          }
        }

      default:
        print(
            "Unhandled key: ${event.logicalKey.keyLabel} (${event.logicalKey.keyId}) type: ${event.deviceType.name}");
    }
  }

  late PlayerProvider provider;
  late PlayerDataProvider dataProvider;

  @override
  Widget build(BuildContext context) {
    dataProvider = context.watch<PlayerDataProvider>();
    provider = context.watch<PlayerProvider>();
    return KeyboardListener(
      focusNode: _fn,
      autofocus: true,
      onKeyEvent: _keyListenerEvent,
      child: OrientationBuilder(
        builder: (context, orientation) {
          double LRpadding = 30;
          if (orientation == Orientation.portrait) LRpadding = 10;
          return Padding(
            padding: EdgeInsets.only(
                top: 15, left: LRpadding, right: LRpadding, bottom: 5),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      topControls(),
                      Expanded(
                        child: dataProvider.state.controlsLocked
                            ? lockedCenterControls()
                            : centerControls(context),
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
                                      dataProvider.state.currentTimeStamp,
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
                                      dataProvider.state.maxTimeStamp,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'NunitoSans'),
                                    ),
                                  ],
                                ),
                                if (megaSkipDuration != null)
                                  dataProvider.state.controlsLocked
                                      ? Container()
                                      : megaSkipButton(),
                              ],
                            ),
                            Container(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                height: 20,
                                child: IgnorePointer(
                                  ignoring: dataProvider.state.controlsLocked,
                                  child: Container(
                                    child: SliderTheme(
                                      data: SliderThemeData(
                                          trackHeight: 1.3,
                                          thumbColor: appTheme.accentColor,
                                          activeTrackColor:
                                              appTheme.accentColor,
                                          inactiveTrackColor: Color.fromARGB(
                                              255, 121, 121, 121),
                                          secondaryActiveTrackColor:
                                              Color.fromARGB(
                                                  255, 167, 167, 167),
                                          thumbShape: dataProvider
                                                  .state.controlsLocked
                                              ? SliderComponentShape.noThumb
                                              : RoundSliderThumbShape(
                                                  enabledThumbRadius: 6),
                                          trackShape: EdgeToEdgeTrackShape(),
                                          overlayShape:
                                              SliderComponentShape.noThumb),
                                      child: Slider(
                                        value: dataProvider.state.sliderValue
                                            .toDouble(),
                                        secondaryTrackValue: provider
                                            .controller.buffered
                                            ?.toDouble(),
                                        onChanged: (val) {
                                          setState(() {
                                            // provider.state = provider.state.copyWith();
                                            provider.controller.seekTo(
                                                Duration(seconds: val.toInt()));
                                          });
                                        },
                                        onChangeStart: (value) {
                                          provider.controller.pause();
                                        },
                                        onChangeEnd: (value) {
                                          provider.controller.play();
                                        },
                                        min: 0,
                                        max: (provider.controller.duration ??
                                                0) /
                                            1000,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            BottomControls(),
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
      ),
    );
  }

  ElevatedButton megaSkipButton() {
    return ElevatedButton(
      onPressed: () {
        provider.fastForward(megaSkipDuration!);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Color.fromARGB(68, 0, 0, 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: appTheme.accentColor),
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
                  color: Colors.white,
                  fontFamily: "Rubik",
                  fontSize: 17,
                ),
              ),
            ),
            Icon(
              Icons.fast_forward_rounded,
              color: Colors.white,
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
          if (provider.controller.isBuffering ?? false)
            Container(
              width: 40,
              height: 40,
              child: Center(
                child: CircularProgressIndicator(
                  color: appTheme.accentColor,
                ),
              ),
            ),
        ],
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
              if (!dataProvider.state.controlsLocked)
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
                child: dataProvider.state.controlsLocked
                    ? Container()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.only(left: 20, top: 5),
                            alignment: Alignment.topLeft,
                            child: Text(
                                "Episode ${dataProvider.state.currentEpIndex + 1}",
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
                              "${dataProvider.showTitle}",
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
              if (kDebugMode && !dataProvider.state.controlsLocked)
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        backgroundColor: Colors.black,
                        contentTextStyle: TextStyle(color: Colors.white),
                        title: Text("VideoStream info",
                            style: TextStyle(color: appTheme.accentColor)),
                        content: Text(
                          //Resolution: ${qualities.where((element) => element['link'] == currentQualityLink).toList()[0]?? ['resolution'] ?? ''}   idk
                          "Aspect Ratio: 16:9 (probably) \nServer: ${dataProvider.state.preferredServer} \nSource: ${dataProvider.state.currentStream.server} ${dataProvider.state.currentStream.backup ? "\(backup\)" : ''}",
                        ),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.info_rounded,
                    color: Colors.white,
                  ),
                ),
              if (!dataProvider.state.controlsLocked)
                IconButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PlayerSetting())).then((val) {
                      dataProvider.initSubsettings();
                      // Restore View state (subtitle screen may change the view type)
                      SystemChrome.setEnabledSystemUIMode(
                          SystemUiMode.immersiveSticky);
                      SystemChrome.setPreferredOrientations([
                        DeviceOrientation.landscapeLeft,
                        DeviceOrientation.landscapeRight,
                      ]);
                    });
                  },
                  tooltip: "Player settings",
                  icon: Icon(
                    Icons.video_settings_rounded,
                    color: Colors.white,
                  ),
                ),
              IconButton(
                onPressed: () {
                  dataProvider.toggleControlsLock();
                },
                icon: Icon(
                  !dataProvider.state.controlsLocked
                      ? Icons.lock_open_rounded
                      : Icons.lock_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
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
          Material(
            color: Colors.transparent,
            child: Container(
              margin: EdgeInsets.only(right: 5),
              height: 65,
              width: 65,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  if (dataProvider.state.currentEpIndex == 0)
                    return floatingSnackBar("Already on the first episode");
                  showSheet(
                    context,
                    CustomControlsBottomSheet(
                      index: dataProvider.state.currentEpIndex - 1,
                      dataProvider: dataProvider,
                      playerProvider: provider,
                    ),
                  );
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
                  provider
                      .fastForward(skipDuration != null ? -skipDuration! : -10);
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
            child: !(provider.controller.isBuffering ?? false)
                ? Material(
                    color: Colors.transparent,
                    child: Container(
                      margin: EdgeInsets.only(left: 5, right: 5),
                      height: 65,
                      width: 65,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          if (provider.state.playerState ==
                              PlayerState.playing) {
                            // playPause = Icons.play_arrow_rounded;
                            provider.controller.pause();
                          } else {
                            // playPause = Icons.pause_rounded;
                            provider.controller.play();
                          }
                          setState(() {});
                        },
                        child: Icon(
                          provider.state.playerState == PlayerState.playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
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
                        color: appTheme.accentColor,
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
                  provider.fastForward(skipDuration ?? 10);
                },
                child: Icon(
                  Icons.fast_forward_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
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
                  if (dataProvider.state.currentEpIndex + 1 ==
                      dataProvider.epLinks.length)
                    return floatingSnackBar(
                        "You are already in the final episode!");
                  if (dataProvider.state.preloadedSources.isNotEmpty) {
                    print("from preload");
                    provider.playPreloadedEpisode(dataProvider);
                  } else
                    showSheet(
                      context,
                      CustomControlsBottomSheet(
                        index: dataProvider.state.currentEpIndex + 1,
                        dataProvider: dataProvider,
                        playerProvider: provider,
                      ),
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

  void showSheet(BuildContext context, Widget child) => showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: appTheme.modalSheetBackgroundColor,
      context: context,
      builder: (BuildContext context) {
        return child;
      });
}

class BottomControls extends StatelessWidget {
  const BottomControls({super.key});

  void showSheet(BuildContext context, Widget child) => showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: appTheme.modalSheetBackgroundColor,
      context: context,
      builder: (BuildContext context) {
        return child;
      });

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.read<PlayerDataProvider>();
    final playerProvider = context.read<PlayerProvider>();

    return dataProvider.state.controlsLocked
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
                                      style: TextStyle(
                                          color: appTheme.textMainColor,
                                          fontFamily: "Rubik",
                                          fontSize: 20),
                                    ),
                                  ),
                                  ListView.builder(
                                    itemCount:
                                        dataProvider.state.qualities.length,
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemBuilder: (BuildContext context, index) {
                                      return Container(
                                        padding: EdgeInsets.only(
                                            left: 25, right: 25),
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            final src = dataProvider.state
                                                .qualities[index]['link']!;
                                            // selectedQuality = dataProvider.state.qualities[index]['quality'] ?? '720';
                                            dataProvider.updateCurrentQuality(
                                                dataProvider
                                                    .state.qualities[index]);
                                            playerProvider.playVideo(src,
                                                currentStream: dataProvider
                                                    .state.currentStream,
                                                preserveProgress: true);
                                            Navigator.pop(context);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              // side: BorderSide(color: Colors.white)
                                            ),
                                            backgroundColor: dataProvider.state
                                                            .qualities[index]
                                                        ['link'] ==
                                                    dataProvider.state
                                                        .currentQuality['link']
                                                ? appTheme.accentColor
                                                : appTheme.backgroundSubColor,
                                          ),
                                          child: Text(
                                            "${dataProvider.state.qualities[index]['quality']}",
                                            style: TextStyle(
                                              color: dataProvider.state
                                                              .qualities[index]
                                                          ['link'] ==
                                                      dataProvider.state
                                                              .currentQuality[
                                                          'link']
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
                        showSheet(
                          context,
                          CustomControlsBottomSheet(
                            index: dataProvider.state.currentEpIndex,
                            dataProvider: dataProvider,
                            playerProvider: playerProvider,
                          ),
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
                            padding:
                                EdgeInsets.only(left: 20, right: 20, top: 15),
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
                                  height:
                                      MediaQuery.of(context).size.height - 150,
                                  child: GridView.builder(
                                    itemCount: dataProvider.epLinks.length,
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            childAspectRatio: 4),
                                    shrinkWrap: true,
                                    padding:
                                        EdgeInsets.only(left: 10, right: 10),
                                    itemBuilder: (context, index) {
                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.pop(context);
                                          if (index ==
                                              dataProvider.state.currentEpIndex)
                                            return;
                                          sheet2(index, context, playerProvider,
                                              dataProvider);
                                        },
                                        child: Container(
                                          margin: EdgeInsets.all(5),
                                          height: 50,
                                          decoration: BoxDecoration(
                                              color: index ==
                                                      dataProvider
                                                          .state.currentEpIndex
                                                  ? appTheme.accentColor
                                                  : appTheme.backgroundSubColor,
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                          alignment: Alignment.center,
                                          child: Text(
                                            "Episode ${index + 1}",
                                            style: TextStyle(
                                              color: index ==
                                                      dataProvider
                                                          .state.currentEpIndex
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
                            return playBackSpeedDialog(
                                context, playerProvider, dataProvider);
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
                          playerProvider.toggleSubs();
                        },
                        tooltip: "Subtitles",
                        icon: Icon(
                          !playerProvider.state.showSubs
                              ? Icons.subtitles_outlined
                              : Icons.subtitles_rounded,
                          color: Colors.white,
                        )),
                    IconButton(
                      onPressed: () {
                        playerProvider.cycleViewMode();
                      },
                      icon: Icon(playerProvider.state.currentViewMode.icon),
                      tooltip: playerProvider.state.currentViewMode.desc,
                      color: Colors.white,
                    )
                  ],
                )
              ],
            ),
          );
  }

  void sheet2(
    int index,
    BuildContext context,
    PlayerProvider pp,
    PlayerDataProvider dp,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: appTheme.modalSheetBackgroundColor,
      builder: (context) => CustomControlsBottomSheet(
        index: index,
        dataProvider: dp,
        playerProvider: pp,
      ),
    );
  }

  Widget playBackSpeedDialog(
      BuildContext context, PlayerProvider pp, PlayerDataProvider dp) {
    final playbackSpeeds = pp.playbackSpeeds;
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
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Rubik"),
            ),
          ),
          StatefulBuilder(
            builder: (context, setState) => Container(
              height: 230,
              width: 250,
              child: ListView.builder(
                itemCount: playbackSpeeds.length,
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
                          pp.setSpeed(playbackSpeeds[index]);
                          setState(() {});
                        },
                        child: Row(
                          children: [
                            Radio<double>(
                              value: playbackSpeeds[index],
                              groupValue: pp.state.speed,
                              onChanged: (val) {
                                pp.setSpeed(val ?? 1);
                                setState(() {});
                              },
                            ),
                            Text(playbackSpeeds[index].toString() + "x"),
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
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    return Rect.fromLTWH(offset.dx, trackTop, trackWidth, trackHeight);
  }
}
