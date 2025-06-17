import 'dart:io';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/data/preferences.dart';
import 'package:animestream/core/data/types.dart';
import 'package:animestream/ui/models/widgets/slider.dart';
import 'package:animestream/ui/models/widgets/subtitles/subtitleSettings.dart';
import 'package:animestream/ui/models/widgets/subtitles/subtitleText.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SubtitleSettingPage extends StatefulWidget {
  final bool fromWatchPage;
  const SubtitleSettingPage({super.key, this.fromWatchPage = false});

  @override
  State<SubtitleSettingPage> createState() => _SubtitleSettingPageState();
}

class _SubtitleSettingPageState extends State<SubtitleSettingPage> {
  @override
  void initState() {
    super.initState();

    if (widget.fromWatchPage) {
      SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    // SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // subtitleSettings = SubtitleSettings();
    // settings = subtitleSettings;
    readSubSettings();
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

  void readSubSettings() async {
    UserPreferences.getUserPreferences().then((value) {
      setState(() {
        settings = value.subtitleSettings ?? SubtitleSettings();
        initialised = true;
      });
    });
  }

  Future<void> saveSubSettings() async {
    await UserPreferences.saveUserPreferences(UserPreferencesModal(subtitleSettings: settings));
    print("Sub preference saved!");
  }

  List<String> sentences = [
    "It was a really tiring day...",
    "I've seen this before, almost as if I've lived here before.",
    "Something's really strange. Better check it out alone when its night.",
  ];

  String getSentence(int index) {
    return sentences[index];
  }

  int ind = 0;

  final fonts = ["Rubik", "Poppins", "NotoSans", "NunitoSans", "Inter", "OpenSans"];

  bool initialised = false;
  bool previewMode = false;

  late SubtitleSettings settings;

  TextStyle subTextStyle() {
    return TextStyle(
      fontSize: Platform.isWindows ? settings.fontSize * 1.5 : settings.fontSize,
      fontFamily: settings.fontFamily ?? "Rubik",
      color: settings.textColor,
      fontWeight: settings.bold ? FontWeight.w700 : FontWeight.w500,
      // letterSpacing: -0.2,
      // wordSpacing: 1,
      fontFamilyFallback: ["Poppins"],
      // backgroundColor: widget.settings.backgroundColor.withValues(alpha: widget.settings.backgroundTransparency),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !previewMode,
      onPopInvokedWithResult: (didPop, result) {
        if (previewMode) {
          SystemChrome.setPreferredOrientations(
              [DeviceOrientation.portraitUp, DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
          setState(() {
            previewMode = false;
          });
        }
        // else {
        // Navigator.of(context).pop();
        // }
      },
      child: Scaffold(
        backgroundColor: appTheme.backgroundColor,
        body: previewMode
            ? _preview()
            : Padding(
                padding: MediaQuery.paddingOf(context),
                child: !initialised
                    ? IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: appTheme.textMainColor,
                          size: 35,
                        ),
                      )
                    : Column(
                        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: Icon(
                                  Icons.arrow_back_rounded,
                                  size: 35,
                                  color: appTheme.textMainColor,
                                ),
                              ),
                            ],
                          ),
                          Stack(
                            children: [
                              Container(
                                alignment: Alignment.bottomCenter,
                                padding: EdgeInsets.only(top: 20, bottom: settings.bottomMargin),
                                color: Colors.white,
                                constraints: BoxConstraints(minHeight: 170),
                                margin: EdgeInsets.only(bottom: 40),
                                child: Container(
                                  width: MediaQuery.of(context).size.width / 1.6,
                                  alignment: Alignment.bottomCenter,
                                  child: SubtitleText(
                                    text: getSentence(ind),
                                    style: subTextStyle(),
                                    strokeColor: settings.strokeColor,
                                    strokeWidth: settings.strokeWidth,
                                    backgroundColor: settings.backgroundColor,
                                    backgroundTransparency: settings.backgroundTransparency,
                                    enableShadows: settings.enableShadows,
                                  ),
                                ),
                              ),
                              Align(
                                  alignment: Alignment.bottomRight,
                                  child: IconButton(
                                      onPressed: () {
                                        SystemChrome.setPreferredOrientations(
                                            [DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
                                        setState(() {
                                          previewMode = true;
                                        });
                                      },
                                      icon: Icon(
                                        Icons.fullscreen,
                                        color: Colors.black,
                                      ))),
                            ],
                          ),
                          Expanded(
                            child: ListView(
                              padding: EdgeInsets.only(bottom: 40),
                              shrinkWrap: true,
                              children: [
                                _itemTitle("Font Family"),
                                SizedBox(
                                  height: 220,
                                  child: GridView(
                                    padding: EdgeInsets.only(left: 10, right: 10, bottom: 20),
                                    physics: NeverScrollableScrollPhysics(),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 2,
                                      mainAxisExtent: 75,
                                    ),
                                    // shrinkWrap: true,
                                    children: [
                                      for (var i = 0; i < fonts.length; i++)
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              settings = settings.copyWith(fontFamily: fonts[i]);
                                            });
                                            saveSubSettings();
                                          },
                                          child: Container(
                                            margin: EdgeInsets.all(5),
                                            decoration: BoxDecoration(
                                              color: settings.fontFamily == fonts[i]
                                                  ? appTheme.accentColor
                                                  : appTheme.backgroundSubColor,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Center(
                                              child: Text(
                                                fonts[i],
                                                style: TextStyle(
                                                    color: settings.fontFamily == fonts[i]
                                                        ? appTheme.onAccent
                                                        : appTheme.textMainColor,
                                                    fontFamily: fonts[i]),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                toggleItem("Bold", settings.bold, () {
                                  setState(() {
                                    settings = settings.copyWith(bold: !settings.bold);
                                    saveSubSettings();
                                  });
                                }),
                                toggleItem("Shadows", settings.enableShadows, () {
                                  setState(() {
                                    settings = settings.copyWith(enableShadows: !settings.enableShadows);
                                    saveSubSettings();
                                  });
                                }),
                                _itemTitle("Font Size"),
                                Padding(
                                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40),
                                  child: CustomSlider(
                                    value: settings.fontSize,
                                    onChanged: (val) {
                                      setState(() {
                                        settings = settings.copyWith(fontSize: val);
                                      });
                                    },
                                    onDragEnd: (value) {
                                      saveSubSettings();
                                    },
                                    min: 15,
                                    max: 30,
                                    divisions: (30 - 15),
                                  ),
                                ),
                                _itemTitle("Stroke Width"),
                                Padding(
                                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40),
                                  child: CustomSlider(
                                    value: settings.strokeWidth,
                                    onChanged: (val) {
                                      setState(() {
                                        settings = settings.copyWith(strokeWidth: double.parse(val.toStringAsFixed(2)));
                                      });
                                    },
                                    onDragEnd: (value) {
                                      saveSubSettings();
                                    },
                                    min: 0,
                                    max: 6,
                                    divisions: 10,
                                  ),
                                ),
                                _itemTitle("Background Opacity"),
                                Padding(
                                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40),
                                  child: CustomSlider(
                                    value: settings.backgroundTransparency,
                                    onChanged: (val) {
                                      setState(() {
                                        settings = settings.copyWith(
                                            backgroundTransparency: double.parse(val.toStringAsFixed(2)));
                                      });
                                    },
                                    onDragEnd: (value) {
                                      saveSubSettings();
                                    },
                                    min: 0,
                                    max: 1,
                                    divisions: 10,
                                  ),
                                ),
                                _itemTitle("Bottom margin"),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 20,
                                    right: 20,
                                  ),
                                  child: CustomSlider(
                                    value: settings.bottomMargin,
                                    onChanged: (val) {
                                      setState(() {
                                        settings =
                                            settings.copyWith(bottomMargin: double.parse(val.toStringAsFixed(2)));
                                      });
                                    },
                                    onDragEnd: (value) {
                                      saveSubSettings();
                                    },
                                    min: 0,
                                    max: 50,
                                    divisions: 50,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
      ),
    );
  }

  Widget _preview() {
    return Stack(children: [
      Container(
        alignment: Alignment.bottomCenter,
        padding: EdgeInsets.only(top: 20, bottom: settings.bottomMargin),
        color: Colors.white,
        height: MediaQuery.of(context).size.height,
        // margin: EdgeInsets.only(bottom: settings.bottomMargin),
        child: Container(
          margin: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
          width: MediaQuery.of(context).size.width / 1.6,
          alignment: Alignment.bottomCenter,
          child: SubtitleText(
            text: getSentence(ind),
            style: subTextStyle(),
            strokeColor: settings.strokeColor,
            strokeWidth: settings.strokeWidth,
            backgroundColor: settings.backgroundColor,
            backgroundTransparency: settings.backgroundTransparency,
            enableShadows: settings.enableShadows,
          ),
        ),
      ),
      Container(
        alignment: Alignment.topRight,
        margin: EdgeInsets.only(
            top: MediaQuery.paddingOf(context).top,
            right: MediaQuery.paddingOf(context).right + 10,
            left: MediaQuery.paddingOf(context).left + 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Preview Mode",
                  style: TextStyle(color: Colors.black, fontSize: 25, fontWeight: FontWeight.bold),
                ),
                IconButton(
                    onPressed: () {
                      SystemChrome.setPreferredOrientations([
                        DeviceOrientation.portraitUp,
                        DeviceOrientation.landscapeRight,
                        DeviceOrientation.landscapeLeft
                      ]);
                      setState(() {
                        previewMode = false;
                      });
                    },
                    icon: Icon(
                      Icons.close,
                      color: Colors.black,
                      size: 30,
                    )),
              ],
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: sentences.length,
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                return Container(
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        ind = index;
                      });
                    },
                    icon: Text("${index + 1}",
                        style: TextStyle(
                          color: Colors.black,
                        )),
                  ),
                );
              },
            )
          ],
        ),
      ),
    ]);
  }

  Center _itemTitle(String title) => Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Text(title, style: TextStyle(fontSize: 20, fontFamily: "Rubik", fontWeight: FontWeight.bold)),
        ),
      );
}
