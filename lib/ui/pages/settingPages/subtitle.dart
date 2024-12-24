import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/data/preferences.dart';
import 'package:animestream/core/data/types.dart';
import 'package:animestream/ui/models/slider.dart';
import 'package:animestream/ui/models/subtitles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SubtitleSettingPage extends StatefulWidget {
  const SubtitleSettingPage({super.key});

  @override
  State<SubtitleSettingPage> createState() => _SubtitleSettingPageState();
}

class _SubtitleSettingPageState extends State<SubtitleSettingPage> {
  @override
  void initState() {
    super.initState();

    // SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // subtitleSettings = SubtitleSettings();
    // settings = subtitleSettings;
    readSubSettings();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void readSubSettings() async {
    UserPreferences().getUserPreferences().then((value) {
      setState(() {
        settings = value.subtitleSettings ?? SubtitleSettings();
        initialised = true;
      });
    });
  }

  Future<void> saveSubSettings() async {
    await UserPreferences().saveUserPreferences(UserPreferencesModal(subtitleSettings: settings));
  }

  String getSentence(int index) {
    final sentences = [
      "It was a really tiring day...",
      "I've seen this before, almost as if I've lived here before.",
      "Something's really strange. Better check it out alone when its night.",
    ];
    return sentences[index];
  }

  int ind = 0;

  final fonts = ["Rubik", "Poppins", "NotoSans", "NunitoSans"];

  bool initialised = false;
  bool previewMode = false;

  late SubtitleSettings settings;

  TextStyle subTextStyle() {
    return TextStyle(
      fontSize: settings.fontSize,
      fontFamily: settings.fontFamily ?? "Rubik",
      color: settings.textColor,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      // wordSpacing: 1,
      fontFamilyFallback: ["Poppins"],
      // backgroundColor: settings.backgroundColor.withValues(alpha: settings.backgroundTransparency),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: previewMode
          ? _preview()
          : Padding(
              padding: MediaQuery.paddingOf(context),
              child: SingleChildScrollView(
                child: !initialised
                    ? IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          size: 35,
                        ),
                      )
                    : Column(
                        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: Icon(
                                    Icons.arrow_back_rounded,
                                    size: 35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Stack(
                            children: [
                              Container(
                                alignment: Alignment.bottomCenter,
                                padding: EdgeInsets.only(top: 20, bottom: 20),
                                color: Colors.white,
                                height: 150,
                                margin: EdgeInsets.only(bottom: settings.bottomMargin),
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
                          _itemTitle("Font Family"),
                          SizedBox(
                            height: 170,
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
                          _itemTitle("Font Size"),
                          Padding(
                            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40),
                            child: CustomSlider(
                              value: settings.fontSize,
                              onChanged: (value) {
                                setState(() {
                                  settings = settings.copyWith(fontSize: value);
                                });
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
                              onChanged: (value) {
                                setState(() {
                                  settings = settings.copyWith(strokeWidth: double.parse(value.toStringAsFixed(2)));
                                });
                                saveSubSettings();
                              },
                              min: 0,
                              max: 1.5,
                              divisions: 15,
                            ),
                          ),
                          _itemTitle("Background Opacity"),
                          Padding(
                            padding: const EdgeInsets.only(left: 20, right: 20),
                            child: CustomSlider(
                              value: settings.backgroundTransparency,
                              onChanged: (value) {
                                setState(() {
                                  settings =
                                      settings.copyWith(backgroundTransparency: double.parse(value.toStringAsFixed(2)));
                                });
                                saveSubSettings();
                              },
                              min: 0,
                              max: 1,
                              divisions: 10,
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
        padding: EdgeInsets.only(top: 20, bottom: 20),
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
          ),
        ),
      ),
      Container(
        alignment: Alignment.topRight,
        margin: EdgeInsets.only(top: MediaQuery.paddingOf(context).top, right: 10),
        child: IconButton(onPressed: () {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.landscapeRight,
            DeviceOrientation.landscapeLeft
          ]);
          setState(() {
            previewMode = false;
          });
        }, icon: Icon(Icons.close, color: Colors.black, size: 30,)),
      ),
    ]);
  }

  Padding _itemTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Text(title, style: TextStyle(fontSize: 20, fontFamily: "Rubik", fontWeight: FontWeight.bold)),
      );
}
