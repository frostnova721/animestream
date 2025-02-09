import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/ui/models/controlsProvider.dart';
import 'package:animestream/ui/models/watchPageUtil.dart';
import 'package:animestream/ui/models/widgets/slider.dart';
import 'package:animestream/ui/theme/themeProvider.dart';
import 'package:animestream/core/commons/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:window_size/window_size.dart';

class Desktopcontrols extends StatefulWidget {
  final VideoController controller;
  final Future<void> Function(int, Stream) refreshPage;
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
  }

  late ControlsProvider provider;

  final _fn = FocusNode();

  bool isFullScreen = false;

  bool isInitiallyMaximized = false;

  Offset prevPos = Offset.zero; // The offset of window before entering fullscreen

  // The size of window before entering fullscreen, set to 1280x720 just as a placeholder value
  // and will be overriden once fullscreen is entered!
  Size prevSize = Size(1280, 720);

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
          break;
        }
    }
  }

  Future<void> setFullScreen(bool fs) async {
    if (fs) {
      isInitiallyMaximized = await windowManager.isMaximized();
      await windowManager.unmaximize();
      final info = await getCurrentScreen();
      prevPos = await windowManager.getPosition();
      prevSize = await windowManager.getSize();
      if (info != null) {
        await windowManager.setPosition(Offset.zero);
        await windowManager.setSize(
          Size(
            info.frame.width / info.scaleFactor,
            info.frame.height / info.scaleFactor,
          ),
        );
      }
    } else {
      if (isInitiallyMaximized) {
        windowManager.maximize();
      } else {
        await windowManager.setPosition(prevPos);
        await windowManager.setSize(prevSize);
      }
    }
    if (mounted) Provider.of<ThemeProvider>(context, listen: false).isFullScreen = fs;
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
                              overlayShape: RoundSliderOverlayShape(overlayRadius: 15)),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [IconButton(onPressed: () {}, icon: makeIcon(Icons.high_quality_outlined))],
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
                      Row(
                        children: [
                          IconButton(onPressed: () {}, icon: makeIcon(Icons.subtitles)),
                          IconButton(
                              onPressed: () {
                                isFullScreen = !isFullScreen;
                                setFullScreen(isFullScreen);
                                setState(() {});
                              },
                              icon: makeIcon(isFullScreen ? Icons.fullscreen_exit_sharp : Icons.fullscreen_sharp)),
                        ],
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
                          onTap: () {},
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
                              index.toString(),
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
    setFullScreen(false);
    super.dispose();
  }
}
