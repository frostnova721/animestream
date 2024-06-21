import 'package:animestream/ui/pages/settingPages/account.dart';
import 'package:animestream/ui/pages/settingPages/appInfo.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:animestream/ui/pages/settingPages/general.dart';
import 'package:animestream/ui/pages/settingPages/player.dart';
import 'package:animestream/ui/pages/settingPages/theme.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';

class NewSettingsPage extends StatefulWidget {
  const NewSettingsPage({super.key});

  @override
  State<NewSettingsPage> createState() => _NewSettingsPageState();
}

class SettingItem {
  final IconData icon;
  final String label;
  final Widget navigateTo;
  final String description;

  SettingItem({
    required this.icon,
    required this.label,
    required this.navigateTo,
    required this.description,
  });
}

class _NewSettingsPageState extends State<NewSettingsPage> {
  final List<SettingItem> settingItems = [
    SettingItem(
        icon: Icons.account_circle, label: "Account", description: "Personal stuff", navigateTo: AccountSetting()),
    SettingItem(icon: Icons.brush_rounded, label: "UI", description: "Colors n Visuals", navigateTo: ThemeSetting()),
    SettingItem(
        icon: Icons.play_circle_fill_rounded,
        label: "Player",
        description: "Tailor your playback",
        navigateTo: PlayerSetting()),
    SettingItem(icon: Icons.tune_rounded, label: "General", description: "Basic tweaks", navigateTo: GeneralSetting()),
    SettingItem(
        icon: Icons.info_outline_rounded, label: "App Info", description: "The App stuff", navigateTo: AppInfoSetting())
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: settingPagesAppBar(context),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.only( left: MediaQuery.of(context).padding.left),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              Container(
                padding: EdgeInsets.only(top: 40, left: 20, bottom: 40),
                child: Text(
                  "Settings",
                  style: TextStyle(fontFamily: "Rubik", fontSize: 40),
                ),
              ),
              ListView.builder(
                itemCount: settingItems.length,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) => Container(
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (context, anim, anim2) {
                            return settingItems[index].navigateTo;
                          },
                          transitionDuration: Duration(milliseconds: 100),
                          reverseTransitionDuration: Duration(milliseconds: 100),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            // final tween = Tween(begin: Offset(1.0, 0.0), end: Offset.zero);
                            // final curvedAnimation = CurvedAnimation(
                            //   parent: animation,
                            //   curve: Curves.ease,
                            // );
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                            // return SlideTransition(
                            //   position: tween.animate(curvedAnimation),
                            //   child: child,
                            // );
                          },
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                settingItems[index].icon,
                                color: textMainColor,
                                size: 40,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 15),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      settingItems[index].label,
                                      style: TextStyle(fontFamily: "NotoSans", fontWeight: FontWeight.bold, fontSize: 20),
                                    ),
                                    Text(
                                      settingItems[index].description,
                                      style: TextStyle(
                                        fontFamily: "NunitoSans",
                                        color: textSubColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.keyboard_arrow_right_rounded,
                            color: textMainColor,
                            size: 30,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
