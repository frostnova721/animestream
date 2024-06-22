import 'package:animestream/core/data/settings.dart';
import 'package:animestream/core/data/types.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';

class PlayerSetting extends StatefulWidget {
  const PlayerSetting({super.key});

  @override
  State<PlayerSetting> createState() => PlayerSettingState();
}

class PlayerSettingState extends State<PlayerSetting> {
  @override
  void initState() {
    super.initState();
    readSettings();
  }

  int? skipDuration;
  int? megaSkipDuration;

  double skipDurationSliderValue = 15;
  double megaSkipDurationSliderValue = 85;

  bool loaded = false;

  String? preferredQuality;

  Future<void> readSettings() async {
    final settings = await Settings().getSettings();
    loaded = true;
    setState(() {
      skipDuration = settings.skipDuration;
      megaSkipDuration = settings.megaSkipDuration;
      preferredQuality = settings.preferredQuality;
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
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        child: Container(
          padding: pagePadding(context, bottom: true),
          child: loaded
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    settingPagesTitleHeader(context, "Player"),
                    Container(
                      padding: EdgeInsets.only(left: 20, right: 20, top: 0),
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
                                    thumbColor: accentColor,
                                    activeTrackColor: accentColor,
                                    inactiveTrackColor: textSubColor,
                                    valueIndicatorShape: RectangularSliderValueIndicatorShape(),
                                    valueIndicatorTextStyle: TextStyle(
                                      color: backgroundColor,
                                      fontFamily: "NotoSans",
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    valueIndicatorColor: accentColor,
                                    trackHeight: 10,
                                    thumbShape: RoundedRectangularThumbShape(width: 10, radius: 5),
                                    activeTickMarkColor: backgroundColor,
                                  ),
                                  child: Slider(
                                    onChanged: (val) {
                                      setState(() {
                                        skipDurationSliderValue = val;
                                      });
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
                                    thumbColor: accentColor,
                                    activeTrackColor: accentColor,
                                    inactiveTrackColor: textSubColor,
                                    valueIndicatorShape: RectangularSliderValueIndicatorShape(),
                                    valueIndicatorTextStyle: TextStyle(
                                      color: backgroundColor,
                                      fontFamily: "NotoSans",
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    valueIndicatorColor: accentColor,
                                    trackHeight: 10,
                                    thumbShape: RoundedRectangularThumbShape(width: 10, radius: 5),
                                    activeTickMarkColor: backgroundColor,
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
                                      backgroundColor: backgroundSubColor,
                                      selectedBackgroundColor: accentColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      side: BorderSide(color: textSubColor)
                                    ),
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
    return Container(padding: EdgeInsets.only(top: 15, bottom: 15), child: child,);
  }

  ButtonSegment segment(String label) {
    return ButtonSegment(
      value: label,
      label: Text(
        label,
        style: TextStyle(
          color: preferredQuality == label ? backgroundColor : accentColor,
          fontSize: 16,
          fontFamily: "NotoSans",
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class RoundedRectangularThumbShape extends SliderComponentShape {
  final double width;
  final double radius;

  RoundedRectangularThumbShape({required this.radius, required this.width});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(width, 10);
  }

  @override
  void paint(PaintingContext context, Offset center,
      {required Animation<double> activationAnimation,
      required Animation<double> enableAnimation,
      required bool isDiscrete,
      required TextPainter labelPainter,
      required RenderBox parentBox,
      required SliderThemeData sliderTheme,
      required TextDirection textDirection,
      required double value,
      required double textScaleFactor,
      required Size sizeWithOverflow}) {
    final rect = Rect.fromCenter(center: center, width: width, height: 20);
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()..color = accentColor,
    );
  }
}
