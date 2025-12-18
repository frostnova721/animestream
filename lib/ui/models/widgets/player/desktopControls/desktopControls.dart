import 'dart:math';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/ui/models/bottomSheets/customControlsSheet.dart';
import 'package:animestream/ui/models/providers/playerDataProvider.dart';
import 'package:animestream/ui/models/providers/playerProvider.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/models/widgets/ContextMenu.dart';
import 'package:animestream/ui/models/widgets/player/desktopControls/pipMode.dart';
import 'package:animestream/ui/models/widgets/slider.dart';
import 'package:animestream/ui/models/providers/appProvider.dart';
import 'package:animestream/ui/pages/settingPages/subtitle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class DesktopControls extends StatefulWidget {
  const DesktopControls({
    super.key,
  });

  @override
  State<DesktopControls> createState() => _DesktopControlsState();
}

class _DesktopControlsState extends State<DesktopControls> {
  // late VideoController controller;

  @override
  void initState() {
    super.initState();
  }

  late PlayerProvider provider;
  late PlayerDataProvider dataProvider;

  final _fn = FocusNode();

  void keyListener(KeyEvent key) async {
    if (key is KeyUpEvent) return;
    switch (key.logicalKey) {
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.mediaPlayPause:
        {
          (provider.controller.isPlaying ?? false) ? provider.controller.pause() : provider.controller.play();
          break;
        }
      case LogicalKeyboardKey.mediaPlay:
        provider.controller.play();
        break;
      case LogicalKeyboardKey.mediaPause:
        provider.controller.pause();
        break;
      case LogicalKeyboardKey.f11:
        {
          final tp = context.read<AppProvider>();
          tp.setFullScreen(!tp.isFullScreen);
          break;
        }

      // Seeking
      case LogicalKeyboardKey.arrowLeft:
        {
          await provider.fastForward(-(currentUserSettings?.skipDuration ?? 15));
          break;
        }
      case LogicalKeyboardKey.arrowRight:
        {
          await provider.fastForward((currentUserSettings?.skipDuration ?? 15));
          break;
        }

      // Volume controls
      case LogicalKeyboardKey.keyM:
        {
          if (provider.state.volume != 0) {
            restorableVolume = provider.state.volume;
            provider.updateVolume(0.0);
          } else {
            provider.updateVolume(restorableVolume);
          }
          break;
        }
      case LogicalKeyboardKey.arrowUp:
        {
          final vol = provider.state.volume + 0.2;
          provider.updateVolume(vol.clamp(0, 1));
          break;
        }
      case LogicalKeyboardKey.arrowDown:
        {
          final vol = provider.state.volume - 0.2;
          provider.updateVolume(vol.clamp(0, 1));
          break;
        }
    }
  }

  double restorableVolume = 0;

  @override
  Widget build(BuildContext context) {
    provider = context.watch<PlayerProvider>();
    dataProvider = context.watch<PlayerDataProvider>();

    if (provider.state.pip) {
      return PipUi(playerProvider: provider, dataProvider: dataProvider);
    }

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
                              style: TextStyle(fontSize: 35, color: Colors.white),
                            ),
                            Text(
                              dataProvider.showTitle,
                              style: TextStyle(fontSize: 17, color: Colors.white),
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
                              useRootNavigator: false,
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
                        Text(
                          dataProvider.state.currentTimeStamp,
                          style: TextStyle(color: Colors.white),
                        ),
                        SliderTheme(
                          data: SliderThemeData(
                              activeTrackColor: appTheme.accentColor,
                              trackHeight: 1,
                              thumbShape: RoundedRectangularThumbShape(width: 2, height: 15),
                              thumbColor: Colors.white,
                              overlayColor: Colors.white.withAlpha(20),
                              inactiveTrackColor: appTheme.textSubColor,
                              secondaryActiveTrackColor: Colors.white,
                              overlayShape: RoundSliderOverlayShape(overlayRadius: 10)),
                          child: Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 10, right: 10),
                              child: Slider(
                                value: dataProvider.state.sliderValue.toDouble(),
                                thumbColor: Colors.white,
                                onChanged: (val) {
                                  provider.controller.seekTo(Duration(seconds: val.toInt()));
                                },
                                min: 0,
                                max: (provider.controller.duration ?? 0) / 1000,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          dataProvider.state.maxTimeStamp,
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  useRootNavigator: false,
                                  builder: (BuildContext context) {
                                    return sideBox();
                                  },
                                );
                              },
                              icon: makeIcon(
                                Icons.high_quality_outlined,
                              ),
                            ),
                            IconButton(
                              // tooltip: "Enter PiP Mode",
                              onPressed: () {
                                provider.setPip(!provider.state.pip);
                              },
                              icon: makeIcon(
                                Icons.picture_in_picture,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                              onPressed: () {
                                if (dataProvider.state.currentEpIndex == 0)
                                  return floatingSnackBar("Already on the first episode");
                                showDialog(
                                    context: context,
                                    useRootNavigator: false,
                                    builder: (BuildContext context) {
                                      return CustomControlsBottomSheet(
                                        index: dataProvider.state.currentEpIndex - 1,
                                        dataProvider: dataProvider,
                                        playerProvider: provider,
                                      );
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
                                  return floatingSnackBar("You are already in the final episode!");
                                if (dataProvider.state.preloadedSources.isNotEmpty) {
                                  print("from preload");
                                  provider.playPreloadedEpisode(dataProvider);
                                } else
                                  showDialog(
                                    context: context,
                                    useRootNavigator: false,
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
                            InkWell(
                                onTap: () {
                                  if (provider.state.volume != 0) {
                                    restorableVolume = provider.state.volume;
                                    provider.updateVolume(0.0);
                                  } else {
                                    provider.updateVolume(restorableVolume);
                                  }
                                },
                                child: makeIcon(Icons.volume_up_sharp)),
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: SliderTheme(
                                data: SliderThemeData(
                                  activeTrackColor: appTheme.accentColor,
                                  trackHeight: 1,
                                  thumbShape: RoundedRectangularThumbShape(width: 2, height: 15),
                                  overlayColor: Colors.white.withAlpha(20),
                                  inactiveTrackColor: appTheme.textSubColor,
                                  secondaryActiveTrackColor: Colors.white,
                                  overlayShape: RoundSliderOverlayShape(overlayRadius: 15),
                                ),
                                child: Slider(
                                  value: provider.state.volume,
                                  onChanged: (value) {
                                    final expVol = pow(value, 3).toDouble();
                                    provider.controller.setVolume(expVol);
                                    provider.updateVolume(value);
                                  },
                                  min: 0,
                                  max: 1,
                                ),
                              ),
                            ),

                            ContextMenu(
                              menuItems: [
                                ContextMenuItem(
                                    icon: Icons.open_in_new,
                                    label: "Customize Subs",
                                    onClick: () {
                                      Navigator.of(context)
                                          .push(MaterialPageRoute(builder: (ctx) => SubtitleSettingPage()))
                                          .then((v) => dataProvider.initSubsettings());
                                    })
                              ],
                              child: IconButton(
                                  onPressed: () {
                                    provider.toggleSubs();
                                  },
                                  icon: makeIcon(provider.state.showSubs ? Icons.subtitles : Icons.subtitles_outlined)),
                            ),
                            IconButton(
                                onPressed: () {
                                  final tp = context.read<AppProvider>();
                                  tp.setFullScreen(!tp.isFullScreen);
                                },
                                icon: makeIcon(context.select<AppProvider, bool>((prov) => prov.isFullScreen)
                                    ? Icons.fullscreen_exit_sharp
                                    : Icons.fullscreen_sharp)),
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

  Widget sideBox({int initialIndex = 0}) {
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
            initialIndex: initialIndex,
            child: Builder(builder: (context) {
              const textStyle = TextStyle(fontWeight: FontWeight.bold);
              return Column(
                children: [
                  TabBar(
                    onTap: (value) => setState(() {}),
                    tabs: [
                      Tab(
                        child: DefaultTabController.of(context).index == 0
                            ? Text(
                                "Qualities",
                                style: textStyle,
                              )
                            : Icon(Icons.hd_outlined),
                      ),
                      Tab(
                        child: DefaultTabController.of(context).index == 1
                            ? Text(
                                "Servers",
                                style: textStyle,
                              )
                            : Icon(Icons.folder_open_outlined),
                      ),
                      Tab(
                        child: DefaultTabController.of(context).index == 2
                            ? Text(
                                "Episodes",
                                style: textStyle,
                              )
                            : Icon(Icons.tv_rounded),
                      ),
                    ],
                  ),
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
                                  behavior: HitTestBehavior.translucent,
                                  onTap: () async {
                                    dataProvider.updateCurrentQuality(dataProvider.state.qualities[index]);
                                    provider.playVideo(dataProvider.state.qualities[index].url,
                                        currentStream: dataProvider.state.currentStream, preserveProgress: true);
                                    setState(() {});
                                  },
                                  child: Container(
                                    color:
                                        dataProvider.state.qualities[index].url == dataProvider.state.currentQuality.url
                                            ? appTheme.accentColor
                                            : null,
                                    height: 40,
                                    alignment: Alignment.center,
                                    child: Text(
                                      "${dataProvider.state.qualities[index].quality}",
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: dataProvider.state.qualities[index].url ==
                                                dataProvider.state.currentQuality.url
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
                                    await provider.playVideo(q.url,
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
                                      useRootNavigator: false,
                                      builder: (context) {
                                        return CustomControlsBottomSheet(
                                          index: index,
                                          dataProvider: dataProvider,
                                          playerProvider: provider,
                                        );
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
              );
            }),
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
