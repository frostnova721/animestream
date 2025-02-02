import 'package:animestream/ui/models/playerUtils.dart';
import 'package:animestream/ui/models/watchPageUtil.dart';
import 'package:animestream/ui/models/widgets/customControls.dart';
import 'package:animestream/ui/models/widgets/slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:window_manager/window_manager.dart';

class Desktopcontrols extends StatefulWidget {
  final VideoController controller;
  const Desktopcontrols({
    super.key,
    required this.controller,
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
        // buffering = controller.isBuffering ?? true;
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

    //calculate the percentage
    // final currentByTotal = (controller.position ?? 0) / (controller.duration ?? 0);
    // if (currentByTotal * 100 >= 75 && !preloadStarted && (controller.isPlaying ?? false)) {
    //   print("====================== above 75% ======================");
    //   print("when position= ${(controller.position ?? 0) / 1000}, duration= ${(controller.duration ?? 0) / 1000} ");
    //   preloadNextEpisode();
    //   widget.updateWatchProgress(currentEpIndex);
    // }
  }

  final _fn = FocusNode();

  String currentTime = "0:00";
  String maxTime = "0:00";

  int sliderValue = 0;

  bool isFullScreen = false;
  bool wakelockEnabled = false;

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
                children: [
                  IconButton(onPressed: () => Navigator.pop(context), icon: makeIcon(Icons.arrow_back_ios_new_sharp))
                ],
              ),
              //stuff in center
              Row(
                children: [],
              ),
              //player controls
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(currentTime),
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 1,
                          thumbShape: RoundedRectangularThumbShape(width: 2, height: 15),
                          overlayColor: Colors.white.withAlpha(20),
                          overlayShape: RoundSliderOverlayShape(overlayRadius: 15)
                        ),
                        child: Expanded(
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
                      Text(maxTime),
                    ],
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
                          IconButton(
                              onPressed: () {
                                (controller.isPlaying ?? false) ? controller.pause() : controller.play();
                                setState(() {});
                              },
                              icon: makeIcon(
                                  (controller.isPlaying ?? false) ? Icons.pause_sharp : Icons.play_arrow_sharp)),
                          IconButton(onPressed: () {}, icon: makeIcon(Icons.skip_next_outlined)),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(onPressed: () {}, icon: makeIcon(Icons.subtitles)),
                          IconButton(
                              onPressed: () {
                                isFullScreen = !isFullScreen;
                                windowManager.setFullScreen(isFullScreen);
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

  Icon makeIcon(IconData id) {
    return Icon(
      id,
      size: 40,
      color: Colors.white,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
