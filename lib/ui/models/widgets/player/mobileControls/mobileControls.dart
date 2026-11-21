import 'package:animestream/ui/models/bottomSheets/customControlsSheet.dart';
import 'package:animestream/ui/models/providers/playerDataProvider.dart';
import 'package:animestream/ui/models/providers/playerProvider.dart';
import 'package:animestream/ui/models/widgets/player/mobileControls/bottomControls.dart';
import 'package:animestream/ui/models/widgets/player/mobileControls/seekBar.dart';
import 'package:animestream/ui/models/widgets/player/mobileControls/topControls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/ui/models/snackBar.dart';

class MobileControls extends StatefulWidget {
  const MobileControls({super.key});

  @override
  State<MobileControls> createState() => _MobileControlsState();
}

class _MobileControlsState extends State<MobileControls> {
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
        if (dataProvider.state.currentEpIndex + 1 == dataProvider.epLinks.length) return;
        provider.playPreloadedEpisode(dataProvider);
        break;
      case LogicalKeyboardKey.mediaTrackPrevious:
        if (dataProvider.state.currentEpIndex == 0) return;
        showSheet(
          context,
          CustomControlsBottomSheet(
            index: dataProvider.state.currentEpIndex - 1,
            dataProvider: dataProvider,
            playerProvider: provider,
          ),
        );
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
        print("Unhandled key: ${event.logicalKey.keyLabel} (${event.logicalKey.keyId}) type: ${event.deviceType.name}");
    }
  }

  late PlayerProvider provider;
  late PlayerDataProvider dataProvider;

  @override
  Widget build(BuildContext context) {
    dataProvider = context.read<PlayerDataProvider>();
    provider = context.read<PlayerProvider>();

    final locked = context.select<PlayerDataProvider, bool>((p) => p.state.controlsLocked);

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
                      TopControls(context: context),
                      Expanded(child: locked ? lockedCenterControls() : centerControls(context)),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _TimeLabel(),
                                if (megaSkipDuration != null) locked ? Container() : megaSkipButton(),
                              ],
                            ),
                            Container(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                height: 20,
                                child: IgnorePointer(
                                  ignoring: locked,
                                  child: Container(
                                    child: SeekBar(
                                      sliderTheme: SliderThemeData(
                                        trackHeight: 1.3,
                                        thumbColor: appTheme.accentColor,
                                        activeTrackColor: appTheme.accentColor,
                                        inactiveTrackColor: Color.fromARGB(255, 121, 121, 121),
                                        secondaryActiveTrackColor: Color.fromARGB(255, 167, 167, 167),
                                        thumbShape: locked
                                            ? SliderComponentShape.noThumb
                                            : RoundSliderThumbShape(enabledThumbRadius: 6),
                                        trackShape: EdgeToEdgeTrackShape(),
                                        overlayShape: SliderComponentShape.noThumb,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const BottomControls(),
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
    int posInSec = (provider.controller.position ?? 0 / 1000).toInt();
    final isAtOp =
        dataProvider.state.opSkip != null &&
        posInSec >= dataProvider.state.opSkip!.start &&
        posInSec <= dataProvider.state.opSkip!.end;
    final isAtEd =
        dataProvider.state.edSkip != null &&
        posInSec >= dataProvider.state.edSkip!.start &&
        posInSec <= dataProvider.state.edSkip!.end;

    return ElevatedButton(
      onPressed: () {
        provider.fastForward(
          isAtOp
              ? dataProvider.state.opSkip!.end - posInSec
              : isAtEd
              ? dataProvider.state.edSkip!.end - posInSec
              : megaSkipDuration!,
        );
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
                isAtOp
                    ? "Skip Op"
                    : isAtEd
                    ? "Skip Ed"
                    : "+$megaSkipDuration",
                style: TextStyle(color: Colors.white, fontFamily: "Rubik", fontSize: 17),
              ),
            ),
            Icon(Icons.fast_forward_rounded, color: Colors.white),
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
              child: Center(child: CircularProgressIndicator(color: appTheme.accentColor)),
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
                  if (dataProvider.state.currentEpIndex == 0) return floatingSnackBar("Already on the first episode");
                  showSheet(
                    context,
                    CustomControlsBottomSheet(
                      index: dataProvider.state.currentEpIndex - 1,
                      dataProvider: dataProvider,
                      playerProvider: provider,
                    ),
                  );
                },
                child: Icon(Icons.skip_previous_rounded, color: Colors.white, size: 40),
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
                child: Icon(Icons.fast_rewind_rounded, color: Colors.white, size: 40),
              ),
            ),
          ),
          _PlayStateIndicator(),
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
                child: Icon(Icons.fast_forward_rounded, color: Colors.white, size: 40),
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
                  if (dataProvider.state.currentEpIndex + 1 == dataProvider.epLinks.length)
                    return floatingSnackBar("You are already in the final episode!");
                  if (dataProvider.state.preloadedSources.isNotEmpty) {
                    print("from preload");
                    provider.playPreloadedEpisode(dataProvider);
                  } else {
                    showSheet(
                      context,
                      CustomControlsBottomSheet(
                        index: dataProvider.state.currentEpIndex + 1,
                        dataProvider: dataProvider,
                        playerProvider: provider,
                      ),
                    );
                  }
                },
                child: Icon(Icons.skip_next_rounded, color: Colors.white, size: 40),
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
    },
  );
}

class _PlayStateIndicator extends StatelessWidget {
  const _PlayStateIndicator();

  @override
  Widget build(BuildContext context) {
    final playState = context.select<PlayerProvider, PlayerState>((p) => p.state.playerState);
    return Container(
      // padding: EdgeInsets.only(left: 35, right: 35),
      child: playState != PlayerState.buffering
          ? Material(
              color: Colors.transparent,
              child: Container(
                margin: EdgeInsets.only(left: 5, right: 5),
                height: 65,
                width: 65,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    if (playState == PlayerState.playing) {
                      // playPause = Icons.play_arrow_rounded;
                      context.read<PlayerProvider>().controller.pause();
                    } else {
                      // playPause = Icons.pause_rounded;
                      context.read<PlayerProvider>().controller.play();
                    }
                  },
                  child: Icon(
                    playState == PlayerState.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
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
              child: Center(child: CircularProgressIndicator(color: appTheme.accentColor)),
            ),
    );
  }
}

class _TimeLabel extends StatelessWidget {
  const _TimeLabel();

  @override
  Widget build(BuildContext context) {
    final (current, max) = context.select<PlayerDataProvider, (String, String)>(
      (p) => (p.state.currentTimeStamp, p.state.maxTimeStamp),
    );
    return Text(
      '$current / $max',
      style: TextStyle(color: Colors.white, fontFamily: 'NunitoSans'),
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
