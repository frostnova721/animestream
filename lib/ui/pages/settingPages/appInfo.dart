import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/app/version.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/models/widgets/ContextMenu.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  int devTapCounter = 0;

  bool loaded = false;

  String appVersion = AppVersion.instance.version;
  String appName = '';
  bool iconPressed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
            padding: pagePadding(context),
            child: loaded
                ? Column(
                    children: [
                      settingPagesTitleHeader(context, "App info"),
                      Container(
                        padding: EdgeInsets.only(top: 50),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                // devTapCounter++;
                                // if (devTapCounter == 10) {
                                //   Settings()
                                //       .writeSettings(SettingsModal(isDev: !(currentUserSettings?.isDev ?? false)));
                                //   if (currentUserSettings?.isDev ?? false)
                                //     floatingSnackBar( "-+-+-+Leaving dev mode+-+-+-");
                                //   else
                                //     floatingSnackBar( "-+-+-+Accessing dev mode+-+-+-");
                                // }
                              },
                              onLongPress: () => setState(() {
                                iconPressed = !iconPressed;
                                showToast("wooosh!!");
                              }),
                              child: ContextMenu(
                                menuItems: [
                                  ContextMenuItem(
                                      icon: Icons.open_in_new,
                                      label: "Open secret link",
                                      onClick: () async {
                                        // HEHE WHY NOT
                                        if (await canLaunchUrl(
                                            Uri.parse("https://www.youtube.com/watch?v=dQw4w9WgXcQ"))) {
                                          launchUrl(
                                            Uri.parse("https://www.youtube.com/watch?v=dQw4w9WgXcQ&autoplay=1"),
                                          );
                                        }
                                      })
                                ],
                                child: Container(
                                    padding: EdgeInsets.only(right: 25),
                                    child: AnimatedSwitcher(
                                      duration: Duration(milliseconds: 400),
                                      switchInCurve: Curves.easeOutCubic,
                                      switchOutCurve: Curves.easeInCubic,
                                      transitionBuilder: (child, animation) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: ScaleTransition(
                                            scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: iconPressed
                                          ? ShaderMask(
                                              shaderCallback: (bounds) => RadialGradient(
                                                      colors: AppVersion.instance.colorCode,
                                                      center: Alignment.bottomLeft,
                                                      radius: 1.5)
                                                  .createShader(bounds),
                                              blendMode: BlendMode.srcIn,
                                              child: Image.asset(
                                                // iconPressed
                                                //     ? 'lib/assets/icons/logo_monochrome.png'
                                                'lib/assets/icons/logo_foreground.png',
                                                height: 100,
                                                width: 100,
                                              ),
                                            )
                                          : Image.asset(
                                              'lib/assets/icons/logo_foreground.png',
                                              height: 100,
                                              width: 100,
                                            ),
                                    )),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Text("animestream",
                                      style: TextStyle(
                                          color: appTheme.textMainColor,
                                          fontFamily: "Poppins",
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold)),
                                ),
                                Text(
                                  "version: $appVersion",
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
                                        await Clipboard.setData(
                                            ClipboardData(text: "https://github.com/frostnova721/animestream"));
                                        floatingSnackBar("link has been copied to clipboard");
                                      },
                                      onTap: () => launchUrl(Uri.parse("https://github.com/frostnova721/animestream"), mode: LaunchMode.externalApplication),
                                      child: Text(
                                        "animestream",
                                        style: TextStyle(
                                          color: appTheme.accentColor,
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
                      if (iconPressed)
                        Padding(
                          padding: const EdgeInsets.only(top: 50),
                          child: Text(
                            "— ${AppVersion.instance.nickname} —",
                            style: TextStyle(
                              fontFamily: "Rubik",
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.bold,
                              color: appTheme.textSubColor.withAlpha((160).toInt()),
                            ),
                          ),
                        ),
                      Container(
                        margin: EdgeInsets.only(top: 50, bottom: MediaQuery.of(context).padding.bottom),
                        child: Text(
                          "Thanks For Downloading!! ❤️",
                          style: TextStyle(color: appTheme.textMainColor, fontFamily: "Rubik", fontSize: 16),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: CircularProgressIndicator(
                      color: appTheme.accentColor,
                    ),
                  )),
      ),
    );
  }

  TextStyle textStyle =
      TextStyle(color: appTheme.textMainColor, fontFamily: 'NotoSans', fontWeight: FontWeight.bold, fontSize: 15);
}
