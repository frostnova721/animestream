import 'package:animestream/core/app/runtimeDatas.dart';
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

    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    subtitleSettings = SubtitleSettings();
    settings = subtitleSettings;
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
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
      backgroundColor: settings.backgroundColor.withOpacity(settings.backgroundTransparency),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
        child: Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(color: Colors.white, width: 720),
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                        onPressed: () => Navigator.of(context).pop(), icon: Icon(Icons.arrow_back_ios_new_rounded)),
                  ],
                ),
                Container(
                  alignment: Alignment.bottomCenter,
                  margin: EdgeInsets.only(bottom: settings.bottomMargin),
                  child: Container(
                    width: MediaQuery.of(context).size.width / 1.6,
                    alignment: Alignment.bottomCenter,
                    child: SubtitleText(
                      text: getSentence(ind),
                      style: subTextStyle(),
                      strokeColor: settings.strokeColor,
                      strokeWidth: settings.strokeWidth,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
