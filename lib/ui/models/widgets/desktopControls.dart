import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/ui/models/playerUtils.dart';
import 'package:animestream/ui/models/watchPageUtil.dart';
import 'package:animestream/ui/models/widgets/slider.dart';
import 'package:animestream/ui/theme/themeProvider.dart';
import 'package:animestream/core/commons/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:window_manager/window_manager.dart';
import 'package:window_size/window_size.dart';

class Desktopcontrols extends StatefulWidget {
  final VideoController controller;
  final Map<String, dynamic> episode;
  final Future<void> Function(int, Stream) refreshPage;
  final Future<void> Function(int) updateWatchProgress;

  const Desktopcontrols({
    super.key,
    required this.controller,
    required this.episode,
    required this.refreshPage,
    required this.updateWatchProgress,
  });

  @override
  State<Desktopcontrols> createState() => _DesktopcontrolsState();
}

class _DesktopcontrolsState extends State<Desktopcontrols> {
  late VideoController controller;

  @override
  void initState() {
    super.initState();

    controller = widget.controller;
    controller.addListener(playerEventListener);
  }

  void playerEventListener() async {
    //manage currentEpIndex and clear preloads if the index changed
    // if (currentEpIndex != widget.episode['currentEpIndex']) {
    //   preloadedSources = [];
    //   preloadStarted = false;
    //   currentEpIndex = widget.episode['currentEpIndex'];
    // }

    //hide the controls on timeout if visible
    // if (widget.isControlsVisible) {
    //   widget.hideControlsOnTimeout();
    // }

    //managing the UI updation
    if (mounted)
      setState(() {
        int duration = ((controller.duration ?? 0) / 1000).toInt();
        int val = ((controller.position ?? 0) / 1000).toInt();
        sliderValue = val;
        // playPause = (controller.isPlaying ?? false) ? Icons.pause_rounded : Icons.play_arrow_rounded;
        currentTime = getFormattedTime(val);
        maxTime = getFormattedTime(duration);
        buffering = controller.isBuffering ?? true;
      });

    if ((controller.isPlaying ?? false) && !wakelockEnabled) {
      WakelockPlus.enable();
      wakelockEnabled = true;
      debugPrint("wakelock enabled");
    } else if (!(controller.isPlaying ?? false) && wakelockEnabled) {
      WakelockPlus.disable();
      wakelockEnabled = false;
      debugPrint("wakelock disabled");
    }

    //play the loaded episode if equal to duration
    // if (!finalEpisodeReached &&
    //     controller.duration != null &&
    //     (controller.position ?? 0) / 1000 == (controller.duration ?? 0) / 1000) {
    //   if (controller.isPlaying ?? false) {
    //     await controller.pause();
    //   }
    // await playPreloadedEpisode();
    // }

    // calculate the percentage
    // final currentByTotal = (controller.position ?? 0) / (controller.duration ?? 0);
    // if (currentByTotal * 100 >= 75 && !preloadStarted && (controller.isPlaying ?? false)) {
    //   print("====================== above 75% ======================");
    //   print("when position= ${(controller.position ?? 0) / 1000}, duration= ${(controller.duration ?? 0) / 1000} ");
    // preloadNextEpisode();
    // widget.updateWatchProgress(currentEpIndex);
    // }
  }

  final _fn = FocusNode();

  String currentTime = "0:00";
  String maxTime = "0:00";

  int sliderValue = 0;

  bool isFullScreen = false;
  bool wakelockEnabled = false;
  bool buffering = true;

  Offset prevPos = Offset.zero; // The offset of window before entering fullscreen

  // The size of window before entering fullscreen, set to 1280x720 just as a placeholder value
  // and will be overriden once fullscreen is entered!
  Size prevSize = Size(1280, 720);

  void keyListener(KeyEvent key) {
    if (key is KeyUpEvent) return;
    switch (key.logicalKey) {
      case LogicalKeyboardKey.space:
        {
          (controller.isPlaying ?? false) ? controller.pause() : controller.play();
          break;
        }
    }
  }

  Future<void> setFullScreen(bool fs) async {
    if (fs) {
      final docked = await windowManager.isDocked();
      if (docked != null) await windowManager.undock();
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
      await windowManager.setPosition(prevPos);
      await windowManager.setSize(prevSize);
    }
    Provider.of<ThemeProvider>(context, listen: false).isFullScreen = fs;
  }

  @override
  Widget build(BuildContext context) {
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
                              "Episode ${widget.episode['currentEpIndex'] + 1}",
                              style: TextStyle(fontSize: 35),
                            ),
                            Text(
                              widget.episode['showTitle'],
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
                        Text(currentTime),
                        SliderTheme(
                          data: SliderThemeData(
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
                                value: sliderValue.toDouble(),
                                onChanged: (val) {
                                  controller.seekTo(Duration(seconds: val.toInt()));
                                },
                                min: 0,
                                max: (controller.duration ?? 0) / 1000,
                              ),
                            ),
                          ),
                        ),
                        Text(maxTime),
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
                                  (controller.isPlaying ?? false) ? controller.pause() : controller.play();
                                  setState(() {});
                                },
                                icon: makeIcon(
                                    (controller.isPlaying ?? false) ? Icons.pause_sharp : Icons.play_arrow_sharp,
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
                      itemCount: widget.episode['epLinks'].length ?? 0,
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 70),
                      itemBuilder: (context, index) {
                        return InkWell(
                          onTap: () {},
                          child: Container(
                            decoration: BoxDecoration(
                              color: index == widget.episode['currentEpIndex']
                                  ? appTheme.accentColor
                                  : appTheme.backgroundSubColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            margin: EdgeInsets.all(3),
                            child: Text(
                              index.toString(),
                              style: TextStyle(
                                color: index == widget.episode['currentEpIndex']
                                    ? appTheme.onAccent
                                    : appTheme.textMainColor,
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
