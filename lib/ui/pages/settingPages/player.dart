import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/data/settings.dart';
import 'package:animestream/core/data/types.dart';
import 'package:animestream/ui/models/widgets/slider.dart';
import 'package:animestream/ui/models/widgets/toggleItem.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:animestream/ui/pages/settingPages/subtitle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlayerSetting extends StatefulWidget {
  final bool fromWatchPage;
  const PlayerSetting({super.key, this.fromWatchPage = false});

  @override
  State<PlayerSetting> createState() => PlayerSettingState();
}

class PlayerSettingState extends State<PlayerSetting> {
  @override
  void initState() {
    if (widget.fromWatchPage) {
      SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.initState();
    readSettings();
  }

  int? skipDuration;
  int? megaSkipDuration;

  late double skipDurationSliderValue;
  late double megaSkipDurationSliderValue;

  bool loaded = false;

  String? preferredQuality;

  late bool enableSuperSpeeds;
  late bool doubleTapToSkip;

  Future<void> readSettings() async {
    final settings = await Settings().getSettings();
    loaded = true;
    setState(() {
      skipDuration = settings.skipDuration ?? 15;
      megaSkipDuration = settings.megaSkipDuration ?? 85;
      preferredQuality = settings.preferredQuality;
      skipDurationSliderValue = skipDuration!.toDouble();
      megaSkipDurationSliderValue = megaSkipDuration!.toDouble();
      enableSuperSpeeds = settings.enableSuperSpeeds ?? false;
      doubleTapToSkip = settings.doubleTapToSkip ?? true;
    });
  }

  Future<void> writeSettings(SettingsModal settings) async {
    await Settings().writeSettings(settings);
    setState(() {
      readSettings();
    });
  }

  Set selectedQualitySet = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Container(
          padding: pagePadding(context, bottom: true),
          child: loaded
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    settingPagesTitleHeader(context, "Player"),
                    Container(
                      // padding: EdgeInsets.only(left: 20, right: 20, top: 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          item(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(bottom: 10),
                                  child: Text(
                                    "Skip duration",
                                    style: textStyle(),
                                  ),
                                ),
                                SliderTheme(
                                  data: SliderThemeData(
                                    thumbColor: appTheme.accentColor,
                                    activeTrackColor: appTheme.accentColor,
                                    inactiveTrackColor: appTheme.textSubColor,
                                    valueIndicatorShape: RoundedSliderValueIndicator(height: 30, width: 35, radius: 5),
                                    valueIndicatorTextStyle: TextStyle(
                                      color: appTheme.backgroundColor,
                                      fontFamily: "NotoSans",
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    valueIndicatorColor: appTheme.accentColor,
                                    trackHeight: 13,
                                    trackShape: MarginedTrack(),
                                    thumbShape: RoundedRectangularThumbShape(width: 10, radius: 5),
                                    activeTickMarkColor: appTheme.backgroundColor,
                                  ),
                                  child: Slider(
                                    onChanged: (val) {
                                      setState(() {
                                        skipDurationSliderValue = val;
                                      });
                                    },
                                    onChangeEnd: (val) {
                                      writeSettings(SettingsModal(skipDuration: skipDurationSliderValue.toInt()));
                                    },
                                    value: skipDurationSliderValue,
                                    divisions: 9,
                                    label: skipDurationSliderValue.round().toString(),
                                    max: 50,
                                    min: 5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          item(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Text(
                                    "Mega skip duration",
                                    style: textStyle(),
                                  ),
                                ),
                                SliderTheme(
                                  data: SliderThemeData(
                                    thumbColor: appTheme.accentColor,
                                    activeTrackColor: appTheme.accentColor,
                                    inactiveTrackColor: appTheme.textSubColor,
                                    valueIndicatorShape: RoundedSliderValueIndicator(height: 30, width: 40, radius: 5),
                                    valueIndicatorTextStyle: TextStyle(
                                      color: appTheme.backgroundColor,
                                      fontFamily: "NotoSans",
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    valueIndicatorColor: appTheme.accentColor,
                                    trackHeight: 13,
                                    thumbShape: RoundedRectangularThumbShape(width: 10, radius: 5),
                                    trackShape: MarginedTrack(),
                                    activeTickMarkColor: appTheme.backgroundColor,
                                  ),
                                  child: Slider(
                                    onChanged: (val) {
                                      setState(() {
                                        megaSkipDurationSliderValue = val;
                                      });
                                    },
                                    onChangeEnd: (val) {
                                      writeSettings(
                                          SettingsModal(megaSkipDuration: megaSkipDurationSliderValue.toInt()));
                                    },
                                    value: megaSkipDurationSliderValue,
                                    divisions: 26,
                                    label: megaSkipDurationSliderValue.round().toString(),
                                    max: 150,
                                    min: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          item(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Text(
                                    "Preferred quality",
                                    style: textStyle(),
                                  ),
                                ),
                                Container(
                                  alignment: Alignment.center,
                                  child: SegmentedButton(
                                    style: SegmentedButton.styleFrom(
                                        backgroundColor: appTheme.backgroundSubColor,
                                        selectedBackgroundColor: appTheme.accentColor,
                                        selectedForegroundColor: appTheme.onAccent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        side: BorderSide(color: appTheme.textSubColor)),
                                    multiSelectionEnabled: false,
                                    showSelectedIcon: false,
                                    onSelectionChanged: (val) {
                                      setState(() {
                                        preferredQuality = val.first;
                                        writeSettings(SettingsModal(preferredQuality: val.first));
                                      });
                                    },
                                    segments: [
                                      segment("360p"),
                                      segment("480p"),
                                      segment("720p"),
                                      segment("1080p"),
                                    ],
                                    selected: <String>{preferredQuality!},
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.of(context)
                                  .push(MaterialPageRoute(builder: (context) => SubtitleSettingPage()));
                            },
                            child: item(
                              // padding: EdgeInsets.only(top: 10, bottom: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Subtitle settings",
                                        style: textStyle(),
                                      ),
                                      Text(
                                        "customize the subtitles",
                                        style: textStyle().copyWith(color: appTheme.textSubColor, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  Icon(Icons.arrow_forward_ios_rounded)
                                ],
                              ),
                            ),
                          ),
                          toggleItem("Enable super speeds", enableSuperSpeeds,
                              description: "Enable extra player speeds", () {
                            enableSuperSpeeds = !enableSuperSpeeds;
                            writeSettings(SettingsModal(enableSuperSpeeds: enableSuperSpeeds));
                          }),
                          ToggleItem(
                              onTapFunction: () {
                                doubleTapToSkip = !doubleTapToSkip;
                                writeSettings(SettingsModal(doubleTapToSkip: doubleTapToSkip));
                              },
                              label: "Double tap to seek",
                              description: "Double tap left/right to jump $skipDuration seconds",
                              value: doubleTapToSkip)
                        ],
                      ),
                    )
                  ],
                )
              : Container(),
        ),
      ),
    );
  }

  Container item({required Widget child}) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 15, 20, 15),
      child: child,
    );
  }

  ButtonSegment segment(String label) {
    return ButtonSegment(
      value: label,
      label: Text(
        label,
        style: TextStyle(
          // color: preferredQuality == label ? appTheme.backgroundColor : appTheme.accentColor,
          fontSize: 16,
          fontFamily: "NotoSans",
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (widget.fromWatchPage) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }
}
