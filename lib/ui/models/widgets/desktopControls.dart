import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/ui/models/bottomSheets/customControlsSheet.dart';
import 'package:animestream/ui/models/controlsProvider.dart';
import 'package:animestream/ui/models/watchPageUtil.dart';
import 'package:animestream/ui/models/widgets/slider.dart';
import 'package:animestream/ui/theme/themeProvider.dart';
import 'package:animestream/core/commons/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class Desktopcontrols extends StatefulWidget {
  final VideoController controller;
  final Future<void> Function(int, VideoStream) refreshPage;
  final Future<void> Function(int) updateWatchProgress;

  const Desktopcontrols({
    super.key,
    required this.controller,
    required this.refreshPage,
    required this.updateWatchProgress,
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

  late ControlsProvider provider;

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
        case LogicalKeyboardKey.arrowLeft: {
          provider.fastForward(-(currentUserSettings?.skipDuration ?? 15));
          break;
        }
        case LogicalKeyboardKey.arrowRight: {
          provider.fastForward((currentUserSettings?.skipDuration ?? 15));
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    provider = context.watch<ControlsProvider>();
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
                              "Episode ${provider.state.currentEpIndex + 1}",
                              style: TextStyle(fontSize: 35),
                            ),
                            Text(
                              provider.episode['showTitle'] ?? "no title",
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
                        Text(provider.state.currentTime),
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
                                value: provider.state.sliderValue.toDouble(),
                                onChanged: (val) {
                                  provider.controller.seekTo(Duration(seconds: val.toInt()));
                                },
                                min: 0,
                                max: (provider.controller.duration ?? 0) / 1000,
                              ),
                            ),
                          ),
                        ),
                        Text(provider.state.maxTime),
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
                          IconButton(onPressed: () {}, icon: makeIcon(Icons.skip_previous_outlined)),
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
                          IconButton(onPressed: () {}, icon: makeIcon(Icons.skip_next_outlined)),
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
      child: Container(
        height: mq.height / 1.5,
        width: mq.width / 3.5,
        color: appTheme.modalSheetBackgroundColor,
        padding: EdgeInsets.all(15),
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              TabBar(tabs: [
                Tab(
                  icon: Icon(Icons.folder_open_outlined),
                ),
                Tab(
                  icon: Icon(Icons.tv_rounded),
                )
              ]),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: TabBarView(children: [
                    Container(),
                    GridView.builder(
                      // shrinkWrap: true,
                      itemCount: provider.episode['epLinks'].length ?? 0,
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 70),
                      itemBuilder: (context, index) {
                        return InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            showDialog(
                                context: context,
                                builder: (context) {
                                  return CustomControlsBottomSheet(
                                      getEpisodeSources: provider.episode['getEpisodeSources'],
                                      currentSources: [],
                                      playVideo: provider.playVideo,
                                      next: false,
                                      epLinks: provider.episode['epLinks'],
                                      currentEpIndex: provider.state.currentEpIndex,
                                      refreshPage: provider.refreshPage,
                                      updateCurrentEpIndex: provider.updateCurrentEpIndex,
                                      customIndex: index,
                                      preferredServer: provider.preferredServer,
                                      );
                                });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: index == provider.state.currentEpIndex
                                  ? appTheme.accentColor
                                  : appTheme.backgroundSubColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            margin: EdgeInsets.all(3),
                            child: Text(
                              (index + 1).toString(),
                              style: TextStyle(
                                color:
                                    index == provider.state.currentEpIndex ? appTheme.onAccent : appTheme.textMainColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  ]),
                ),
              ),
            ],
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
