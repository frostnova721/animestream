import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/ui/models/bottomSheets/customControlsSheet.dart';
import 'package:animestream/ui/models/providers/playerDataProvider.dart';
import 'package:animestream/ui/models/providers/playerProvider.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/models/widgets/slider.dart';
import 'package:animestream/ui/models/providers/themeProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class Desktopcontrols extends StatefulWidget {

  const Desktopcontrols({
    super.key,
  });

  @override
  State<Desktopcontrols> createState() => _DesktopcontrolsState();
}

class _DesktopcontrolsState extends State<Desktopcontrols> {
  // late VideoController controller;

  @override
  void initState() {
    super.initState();
    isFullScreen = context.read<ThemeProvider>().isFullScreen;
  }

  late PlayerProvider provider;
  late PlayerDataProvider dataProvider;

  final _fn = FocusNode();

  late bool isFullScreen;

  void keyListener(KeyEvent key) {
    if (key is KeyUpEvent) return;
    switch (key.logicalKey) {
      case LogicalKeyboardKey.space:
        {
          (provider.controller.isPlaying ?? false) ? provider.controller.pause() : provider.controller.play();
          break;
        }
      case LogicalKeyboardKey.f11:
        {
          isFullScreen = !isFullScreen;
          context.read<ThemeProvider>().setFullScreen(isFullScreen);
          break;
        }
      case LogicalKeyboardKey.arrowLeft:
        {
          provider.fastForward(-(currentUserSettings?.skipDuration ?? 15));
          break;
        }
      case LogicalKeyboardKey.arrowRight:
        {
          provider.fastForward((currentUserSettings?.skipDuration ?? 15));
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    provider = context.watch<PlayerProvider>();
    dataProvider = context.watch<PlayerDataProvider>();
    return KeyboardListener(
        focusNode: _fn,
        onKeyEvent: keyListener,
        autofocus: true,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              //top bar/row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  //top left
                  Row(
                    children: [
                      IconButton(onPressed: () => Navigator.pop(context), icon: makeIcon(Icons.arrow_back)),
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Episode ${dataProvider.state.currentEpIndex + 1}",
                              style: TextStyle(fontSize: 35),
                            ),
                            Text(
                              dataProvider.showTitle,
                              style: TextStyle(fontSize: 17),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  //top right
                  Row(
                    children: [
                      IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return sideBox();
                              },
                            );
                          },
                          icon: makeIcon(Icons.menu_open_sharp))
                    ],
                  ),
                ],
              ),
              //stuff in center
              Row(
                children: [],
              ),
              //player controls
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(dataProvider.state.currentTimeStamp),
                        SliderTheme(
                          data: SliderThemeData(
                              activeTrackColor: appTheme.accentColor,
                              trackHeight: 1,
                              thumbShape: RoundedRectangularThumbShape(width: 2, height: 15),
                              overlayColor: Colors.white.withAlpha(20),
                              inactiveTrackColor: appTheme.textSubColor,
                              secondaryActiveTrackColor: appTheme.textMainColor,
                              overlayShape: RoundSliderOverlayShape(overlayRadius: 10)),
                          child: Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 10, right: 10),
                              child: Slider(
                                value: dataProvider.state.sliderValue.toDouble(),
                                onChanged: (val) {
                                  provider.controller.seekTo(Duration(seconds: val.toInt()));
                                },
                                min: 0,
                                max: (provider.controller.duration ?? 0) / 1000,
                              ),
                            ),
                          ),
                        ),
                        Text(dataProvider.state.maxTimeStamp),
                      ],
                    ),
                  ),
                  Row(
                    // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [IconButton(onPressed: () {}, icon: makeIcon(Icons.high_quality_outlined))],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                              onPressed: () {
                                if (dataProvider.state.currentEpIndex == 0)
                                  return floatingSnackBar(context, "Already on the first episode");
                                showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Container();
                                      // CustomControlsBottomSheet(
                                      // index: ,
                                      // );
                                    });
                              },
                              icon: makeIcon(Icons.skip_previous_outlined)),
                          Padding(
                            padding: const EdgeInsets.only(left: 5, right: 5),
                            child: IconButton(
                                onPressed: () {
                                  (provider.controller.isPlaying ?? false)
                                      ? provider.controller.pause()
                                      : provider.controller.play();
                                  setState(() {});
                                },
                                icon: makeIcon(
                                    (provider.controller.isPlaying ?? false)
                                        ? Icons.pause_sharp
                                        : Icons.play_arrow_sharp,
                                    customSize: 50)),
                          ),
                          IconButton(
                              onPressed: () {
                                if (dataProvider.state.currentEpIndex + 1 == dataProvider.epLinks.length)
                                  return floatingSnackBar(context, "You are already in the final episode!");
                                if (dataProvider.state.preloadedSources.isNotEmpty) {
                                  print("from preload");
                                  provider.playPreloadedEpisode(dataProvider);
                                } else
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return CustomControlsBottomSheet(
                                        index: dataProvider.state.currentEpIndex + 1,
                                        dataProvider: dataProvider,
                                        playerProvider: provider,
                                      );
                                    },
                                  );
                              },
                              icon: makeIcon(Icons.skip_next_outlined)),
                        ],
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // The volume icon and slider
                            makeIcon(Icons.volume_up_sharp),
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: SliderTheme(
                                data: SliderThemeData(
                                  activeTrackColor: appTheme.accentColor,
                                  trackHeight: 1,
                                  thumbShape: RoundedRectangularThumbShape(width: 2, height: 15),
                                  overlayColor: Colors.white.withAlpha(20),
                                  inactiveTrackColor: appTheme.textSubColor,
                                  secondaryActiveTrackColor: appTheme.textMainColor,
                                  overlayShape: RoundSliderOverlayShape(overlayRadius: 15),
                                ),
                                child: Slider(
                                  value: provider.controller.volume ?? 0,
                                  onChanged: (value) => provider.controller.setVolume(value),
                                  min: 0,
                                  max: 1,
                                ),
                              ),
                            ),

                            IconButton(onPressed: () {}, icon: makeIcon(Icons.subtitles)),
                            IconButton(
                                onPressed: () {
                                  isFullScreen = !isFullScreen;
                                  context.read<ThemeProvider>().setFullScreen(isFullScreen);
                                  setState(() {});
                                },
                                icon: makeIcon(isFullScreen ? Icons.fullscreen_exit_sharp : Icons.fullscreen_sharp)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ));
  }

  Widget sideBox() {
    final mq = MediaQuery.sizeOf(context);
    return Dialog(
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.centerRight,
      child: StatefulBuilder(
        builder: (context, setState) => Container(
          height: mq.height / 1.5,
          width: mq.width / 3.5,
          color: appTheme.modalSheetBackgroundColor,
          padding: EdgeInsets.all(15),
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                TabBar(tabs: [
                  Tab(
                    icon: Icon(Icons.hd_outlined),
                  ),
                  Tab(
                    icon: Icon(Icons.folder_open_outlined),
                  ),
                  Tab(
                    icon: Icon(Icons.tv_rounded),
                  ),
                ]),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: TabBarView(
                      children: [
                        ListView.builder(
                          itemCount: dataProvider.state.qualities.length,
                          itemBuilder: (context, index) {
                            return MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () async {
                                  dataProvider.updateCurrentQuality(dataProvider.state.qualities[index]);
                                  provider.playVideo(dataProvider.state.qualities[index]['link']!,
                                      currentStream: dataProvider.state.currentStream);
                                },
                                child: Container(
                                  color:
                                      dataProvider.state.qualities[index]['link'] == provider.controller.activeMediaUrl
                                          ? appTheme.accentColor
                                          : null,
                                  height: 40,
                                  alignment: Alignment.center,
                                  child: Text(
                                    "${dataProvider.state.qualities[index]['quality']}",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: dataProvider.state.qualities[index]['link'] ==
                                              provider.controller.activeMediaUrl
                                          ? appTheme.onAccent
                                          : appTheme.textMainColor,
                                      fontFamily: "Poppins",
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        ListView.builder(
                          itemCount: dataProvider.state.streams.length,
                          itemBuilder: (context, index) {
                            final sources = dataProvider.state.streams;
                            final current = dataProvider.state.currentStream;

                            return MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () async {
                                  dataProvider.updateCurrentStream(dataProvider.state.streams[index]);
                                  await dataProvider.extractCurrentStreamQualities();
                                  final q = dataProvider.getPreferredQualityStreamFromQualities();
                                  await provider.playVideo(q['link']!,
                                      preserveProgress: true, currentStream: dataProvider.state.streams[index]);
                                  setState(() {});
                                },
                                child: Container(
                                  color: sources[index].server == current.server &&
                                          sources[index].quality == current.quality
                                      ? appTheme.accentColor
                                      : null,
                                  height: 40,
                                  alignment: Alignment.center,
                                  child: Text(
                                    "${sources[index].server} | ${sources[index].quality}",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: sources[index].server == current.server &&
                                              sources[index].quality == current.quality
                                          ? appTheme.onAccent
                                          : appTheme.textMainColor,
                                      fontFamily: "Poppins",
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        GridView.builder(
                          // shrinkWrap: true,
                          itemCount: dataProvider.epLinks.length,
                          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 70),
                          itemBuilder: (context, index) {
                            return InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return Container();
                                      // CustomControlsBottomSheet(
                                      //   getEpisodeSources: dataProvider.episode['getEpisodeSources'],
                                      //   currentSources: [],
                                      //   playVideo: dataProvider.playVideo,
                                      //   next: false,
                                      //   epLinks: dataProvider.episode['epLinks'],
                                      //   currentEpIndex: dataProvider.state.currentEpIndex,
                                      //   refreshPage: dataProvider.refreshPage,
                                      //   updateCurrentEpIndex: dataProvider.updateCurrentEpIndex,
                                      //   customIndex: index,
                                      //   preferredServer: dataProvider.preferredServer,
                                      // );
                                    });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: index == dataProvider.state.currentEpIndex
                                      ? appTheme.accentColor
                                      : appTheme.backgroundSubColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                margin: EdgeInsets.all(3),
                                child: Text(
                                  (index + 1).toString(),
                                  style: TextStyle(
                                    color: index == dataProvider.state.currentEpIndex
                                        ? appTheme.onAccent
                                        : appTheme.textMainColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Icon makeIcon(IconData id, {double customSize = 40}) {
    return Icon(
      id,
      size: customSize,
      color: Colors.white,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
