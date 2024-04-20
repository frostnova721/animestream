import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppInfoSetting extends StatefulWidget {
  const AppInfoSetting({super.key});

  @override
  State<AppInfoSetting> createState() => _AppInfoSettingState();
}

class _AppInfoSettingState extends State<AppInfoSetting> {
  @override
  void initState() {
    super.initState();
    getAppDetails();
  }

  Future<void> getAppDetails() async {
    final packageInfo = await PackageInfo.fromPlatform();
    appVersion = packageInfo.version;
    appName = packageInfo.appName;
    setState(() {
      loaded = true;
    });
  }

  bool loaded = false;

  String appVersion = '';
  String appName = '';
  bool iconPressed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Padding(
          padding: pagePadding(context),
          child: loaded
              ? Column(
                  children: [
                    topRow(context, "App info"),
                    Container(
                      padding: EdgeInsets.only(top: 50),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onLongPress: () => setState(() {
                              iconPressed = !iconPressed;
                              floatingSnackBar(context, "WOOSH!!", duration: 1);
                            }),
                            child: Container(
                              padding: EdgeInsets.only(right: 25),
                                child: Image.asset(
                              iconPressed ? 'lib/assets/icons/logo_monochrome.png' :'lib/assets/icons/logo_foreground.png',
                              height: 100,
                              width: 100,
                            )),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text("animestream", style: TextStyle(color: textMainColor, fontFamily: "Poppins", fontSize: 22, fontWeight: FontWeight.bold)),
                              ),
                              Text("package: $appName", style: textStyle),
                              Text(
                                "app version: $appVersion",
                                style: textStyle,
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "github: ",
                                    style: textStyle,
                                  ),
                                  InkWell(
                                    onLongPress: () async {
                                      await Clipboard.setData(ClipboardData(
                                          text:
                                              "https://github.com/frostnova721/animestream"));
                                      floatingSnackBar(context,
                                          "link has been copied to clipboard");
                                    },
                                    onTap: () => launchUrl(Uri.parse(
                                        "https://github.com/frostnova721/animestream")),
                                    child: Text(
                                      "animestream",
                                      style: TextStyle(
                                        color: accentColor,
                                        fontFamily: 'NotoSans',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(margin: EdgeInsets.only(top: 100) ,child: Text("Thanks For Downloading!! ❤️", style: TextStyle(color: textMainColor, fontFamily: "Rubik", fontSize: 16),),)
                  ],
                )
              : Center(
                  child: CircularProgressIndicator(
                    color: accentColor,
                  ),
                )),
    );
  }

  TextStyle textStyle = TextStyle(
      color: textMainColor,
      fontFamily: 'NotoSans',
      fontWeight: FontWeight.bold,
      fontSize: 15);
}
