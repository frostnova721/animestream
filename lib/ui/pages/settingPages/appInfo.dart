import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/app/version.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/models/widgets/ContextMenu.dart';
import 'package:animestream/ui/models/widgets/clickableItem.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:animestream/ui/pages/settingPages/logs.dart';
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
            padding: pagePadding(context, bottom: true),
            child: loaded
                ? Column(
                    children: [
                      settingPagesTitleHeader(context, "App Info"),
                      SizedBox(height: 20),
                      _header(),
                      SizedBox(height: 40),
                      _linksGroup(),
                      SizedBox(height: 30),
                      if (iconPressed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _codename(),
                        ),
                      _footer(),
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

  Widget _header() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            devTapCounter++;
            if (devTapCounter % 5 == 0) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => LogScreen()));
            }
          },
          onLongPress: () => setState(() {
            iconPressed = !iconPressed;
            // showToast(iconPressed ? "Dev mode activated!" : "Dev mode deactivated");
          }),
          child: ContextMenu(
            menuItems: [
              ContextMenuItem(
                  icon: Icons.open_in_new,
                  label: "Open secret link",
                  onClick: () async {
                    if (await canLaunchUrl(Uri.parse("https://www.youtube.com/watch?v=dQw4w9WgXcQ"))) {
                      launchUrl(
                        Uri.parse("https://www.youtube.com/watch?v=dQw4w9WgXcQ&autoplay=1"),
                      );
                    }
                  })
            ],
            child: Container(
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
                              colors: AppVersion.instance.colorCode, center: Alignment.bottomLeft, radius: 1.5)
                          .createShader(bounds),
                      blendMode: BlendMode.srcIn,
                      child: Image.asset(
                        'lib/assets/icons/logo_foreground.png',
                        height: 110,
                        width: 110,
                      ),
                    )
                  : Image.asset(
                      'lib/assets/icons/logo_foreground.png',
                      height: 110,
                      width: 110,
                    ),
            )),
          ),
        ),
        SizedBox(height: 15),
        Text(
          "animestream",
          style: TextStyle(
            color: appTheme.textMainColor,
            fontFamily: "Poppins",
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 5),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: appTheme.backgroundSubColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "v$appVersion",
            style: TextStyle(
              color: appTheme.textSubColor,
              fontFamily: "Rubik",
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _linksGroup() {
    return Container(
      margin: EdgeInsets.only(left: 16, right: 16),
      decoration: BoxDecoration(
        color: appTheme.backgroundSubColor.withAlpha(150),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          ClickableItem(
              onTap: () => launchUrl(
                    Uri.parse("https://github.com/frostnova721/animestream"),
                    mode: LaunchMode.externalApplication,
                  ),
              label: "GitHub Repository",
              description: "Source code n stuff",
              suffixIcon: Icon(Icons.arrow_outward_rounded, size: 20, color: appTheme.textSubColor),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          _divider(),
          ClickableItem(
            onTap: () => launchUrl(
              Uri.parse("https://github.com/frostnova721/animestream/issues"),
              mode: LaunchMode.externalApplication,
            ),
            label: "Report an Issue",
            description: "Found a bug? Let us know!",
            suffixIcon: Icon(Icons.bug_report_rounded, size: 20, color: appTheme.textSubColor),
          ),
          _divider(),
          ClickableItem(
              onTap: () {
                Clipboard.setData(ClipboardData(text: "https://github.com/frostnova721/animestream"));
                floatingSnackBar("Repository link copied!");
              },
              label: "Share App",
              description: "Copy link to clipboard",
              suffixIcon: Icon(Icons.copy_rounded, size: 20, color: appTheme.textSubColor),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
        ],
      ),
    );
  }

  Widget _codename() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        border: Border.all(color: appTheme.accentColor.withAlpha(100)),
        borderRadius: BorderRadius.circular(15),
        color: appTheme.accentColor.withAlpha(20),
      ),
      child: Text(
        "Codename: ${AppVersion.instance.nickname}",
        style: TextStyle(
          color: appTheme.accentColor,
          fontFamily: "Rubik",
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _footer() {
    return Column(
      children: [
        Text(
          "Made with ❤️ & Flutter",
          style: TextStyle(
            color: appTheme.textSubColor,
            fontSize: 12,
            fontFamily: "Poppins",
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      color: appTheme.textSubColor.withAlpha(30),
      indent: 20,
      endIndent: 20,
    );
  }
}
