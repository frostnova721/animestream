import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/ui/models/bottomSheets/customControlsSheet.dart';
import 'package:animestream/ui/models/providers/controlsProvider.dart';
import 'package:animestream/ui/models/snackBar.dart';

class Controls extends StatefulWidget {
  final Widget bottomControls;
  final Widget topControls;
  final bool Function() isControlsLocked;
  final bool isControlsVisible;
  final void Function() hideControlsOnTimeout;

  const Controls({
    super.key,
    required this.bottomControls,
    required this.topControls,
    required this.isControlsLocked,
    required this.hideControlsOnTimeout,
    required this.isControlsVisible,
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
    //this widget will only be open when the video is initialised. so to hide the controls, call it first
    widget.hideControlsOnTimeout();
    context.read<ControlsProvider>().controller.addListener(controlHiderListener);
  }

  void controlHiderListener() {
    if (widget.isControlsVisible) {
      widget.hideControlsOnTimeout();
    }
  }

  int? skipDuration = currentUserSettings?.skipDuration ?? 10;
  int? megaSkipDuration = currentUserSettings?.megaSkipDuration ?? 85;

  //probably redundant function. might remove later
  // void updateCurrentEpIndex(int updatedIndex) {
  //   provider.state;
  //   // sliderValue = 0;
  // }

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
        if (provider.state.currentEpIndex + 1 == provider.episode['epLinks'].length) return;
        provider.playPreloadedEpisode();
        break;
      case LogicalKeyboardKey.mediaTrackPrevious:
        if (provider.state.currentEpIndex == 0) return;
        showModalBottomSheet(
            isScrollControlled: true,
            backgroundColor: appTheme.modalSheetBackgroundColor,
            context: context,
            builder: (BuildContext context) {
              return CustomControlsBottomSheet(
                getEpisodeSources: provider.episode['getEpisodeSources'],
                currentSources: [provider.state.currentSource],
                currentEpIndex: provider.state.currentEpIndex,
                playVideo: provider.playVideo,
                next: false,
                refreshPage: provider.refreshPage,
                epLinks: provider.episode['epLinks'],
                updateCurrentEpIndex: provider.updateCurrentEpIndex,
                preferredServer: provider.preferredServer,
              );
            });
        break;
      case LogicalKeyboardKey.mediaFastForward:
        provider.fastForward(skipDuration ?? 10);
        break;
      case LogicalKeyboardKey.mediaRewind:
        provider.fastForward(-(skipDuration ?? 10));
        break;
      // case LogicalKeyboardKey.select:
      // {
      // if (!provider.isControlsVisible) {
      // widget.toggleControls(!provider.isControlsVisible);
      // widget.hideControlsOnTimeout();
      // }
      // break;
      // }
      // }
      // case LogicalKeyboardKey.f11:

      // case LogicalKeyboardKey.arrowUp:
      // case LogicalKeyboardKey.arrowDown:
      // case LogicalKeyboardKey.arrowLeft:
      // case LogicalKeyboardKey.arrowRight: {
      //   if (!widget.isControlsVisible) {
      //     widget.toggleControls(!widget.isControlsVisible);
      //     widget.hideControlsOnTimeout();
      //   }
      // }

      default:
        print("Unhandled key: ${event.logicalKey.keyLabel} (${event.logicalKey.keyId}) type: ${event.deviceType.name}");
    }
  }

  late ControlsProvider provider;

  @override
  Widget build(BuildContext context) {
    provider = context.watch<ControlsProvider>();
    return KeyboardListener(
      focusNode: _fn,
      autofocus: true,
      onKeyEvent: _keyListenerEvent,
      child: OrientationBuilder(
        builder: (context, orientation) {
          double LRpadding = 30;
          if (orientation == Orientation.portrait) LRpadding = 10;
          return Padding(
            padding: EdgeInsets.only(top: 15, left: LRpadding, right: LRpadding, bottom: 5),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      widget.topControls,
                      Expanded(
                        child: widget.isControlsLocked() ? lockedCenterControls() : centerControls(context),
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
                                      provider.state.currentTime,
                                      style: TextStyle(color: Colors.white, fontFamily: 'NunitoSans'),
                                    ),
                                    const Text(
                                      " / ",
                                      style: TextStyle(color: Colors.white, fontFamily: 'NunitoSans'),
                                    ),
                                    Text(
                                      provider.state.maxTime,
                                      style: TextStyle(color: Colors.white, fontFamily: 'NunitoSans'),
                                    ),
                                  ],
                                ),
                                if (megaSkipDuration != null)
                                  widget.isControlsLocked() ? Container() : megaSkipButton(),
                              ],
                            ),
                            Container(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                height: 20,
                                child: IgnorePointer(
                                  ignoring: widget.isControlsLocked(),
                                  child: Container(
                                    child: SliderTheme(
                                      data: SliderThemeData(
                                          trackHeight: 1.3,
                                          thumbColor: appTheme.accentColor,
                                          activeTrackColor: appTheme.accentColor,
                                          inactiveTrackColor: Color.fromARGB(255, 121, 121, 121),
                                          secondaryActiveTrackColor: Color.fromARGB(255, 167, 167, 167),
                                          thumbShape: widget.isControlsLocked()
                                              ? SliderComponentShape.noThumb
                                              : RoundSliderThumbShape(enabledThumbRadius: 6),
                                          trackShape: EdgeToEdgeTrackShape(),
                                          overlayShape: SliderComponentShape.noThumb),
                                      child: Slider(
                                        value: provider.state.sliderValue.toDouble(),
                                        secondaryTrackValue: provider.controller.buffered?.toDouble(),
                                        onChanged: (val) {
                                          setState(() {
                                            // provider.state = provider.state.copyWith();
                                            provider.controller.seekTo(Duration(seconds: val.toInt()));
                                          });
                                        },
                                        onChangeStart: (value) {
                                          provider.controller.pause();
                                        },
                                        onChangeEnd: (value) {
                                          provider.controller.play();
                                        },
                                        min: 0,
                                        max: (provider.controller.duration ?? 0) / 1000,
                                      ),
                                    ),
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
          if (provider.state.buffering)
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
                  if (provider.state.currentEpIndex == 0)
                    return floatingSnackBar(context, "Already on the first episode");
                  showModalBottomSheet(
                      isScrollControlled: true,
                      backgroundColor: appTheme.modalSheetBackgroundColor,
                      context: context,
                      builder: (BuildContext context) {
                        return CustomControlsBottomSheet(
                          getEpisodeSources: provider.episode['getEpisodeSources'],
                          currentSources: [provider.state.currentSource],
                          currentEpIndex: provider.state.currentEpIndex,
                          playVideo: provider.playVideo,
                          next: false,
                          refreshPage: provider.refreshPage,
                          epLinks: provider.episode['epLinks'],
                          updateCurrentEpIndex: provider.updateCurrentEpIndex,
                          preferredServer: provider.preferredServer,
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
                  provider.fastForward(skipDuration != null ? -skipDuration! : -10);
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
            child: !provider.state.buffering
                ? Material(
                    color: Colors.transparent,
                    child: Container(
                      margin: EdgeInsets.only(left: 5, right: 5),
                      height: 65,
                      width: 65,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          if (provider.state.playerState == PlayerState.playing) {
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
          // Padding(
          // padding: EdgeInsets.only(left: 35),
          // child:
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
                  if (provider.state.currentEpIndex + 1 == provider.episode['epLinks'].length)
                    return floatingSnackBar(context, "You are already in the final episode!");
                  if (provider.state.preloadedSources.isNotEmpty) {
                    print("from preload");
                    provider.playPreloadedEpisode();
                  } else
                    showModalBottomSheet(
                      isScrollControlled: true,
                      backgroundColor: appTheme.modalSheetBackgroundColor,
                      context: context,
                      builder: (BuildContext context) {
                        return CustomControlsBottomSheet(
                          getEpisodeSources: provider.episode['getEpisodeSources'],
                          currentSources: [provider.state.currentSource],
                          currentEpIndex: provider.state.currentEpIndex,
                          playVideo: provider.playVideo,
                          next: true,
                          refreshPage: provider.refreshPage,
                          epLinks: provider.episode['epLinks'],
                          updateCurrentEpIndex: provider.updateCurrentEpIndex,
                          preferredServer: provider.preferredServer,
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
          ),
          // ),
        ],
      ),
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
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    return Rect.fromLTWH(offset.dx, trackTop, trackWidth, trackHeight);
  }
}
