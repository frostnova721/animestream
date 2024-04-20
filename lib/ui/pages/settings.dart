import 'package:animestream/ui/pages/settingPages/account.dart';
import 'package:animestream/ui/pages/settingPages/appInfo.dart';
import 'package:animestream/ui/pages/settingPages/general.dart';
import 'package:animestream/ui/pages/settingPages/player.dart';
import 'package:animestream/ui/pages/settingPages/theme.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsState();
}

class _SettingsState extends State<SettingsPage> {
  final List<SettingItem> items = [
    SettingItem(label: "Account", page: AccountSetting()),
    SettingItem(label: "Theme", page: ThemeSetting()),
    SettingItem(label: "General", page: GeneralSetting()),
    SettingItem(label: "Player", page: PlayerSetting()),
    SettingItem(label: "App info", page: AppInfoSetting()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top,
          left: MediaQuery.of(context).padding.left,
          right: MediaQuery.of(context).padding.right
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: textMainColor,
                      size: 32,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(
                      "Settings",
                      style: TextStyle(
                        fontFamily: "Rubik",
                        fontSize: 23,
                        color: textMainColor,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                // padding: EdgeInsets.only(left: 20, right: 20),
                child: ListView.builder(
                  itemCount: items.length,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      items[index].page,
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                final tween = Tween(
                                    begin: Offset(1.0, 0.0), end: Offset.zero);
                                final curvedAnimation = CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.ease,
                                );
          
                                return SlideTransition(
                                  position: tween.animate(curvedAnimation),
                                  child: child,
                                );
                              },
                            ));
                        // MaterialPageRoute(
                        //   builder: (context) => items[index].page,
                        // ));
                      },
                      child: Container(
                        height: 70,
                        padding: EdgeInsets.only(left: 20, right: 20),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          // mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              items[index].label,
                              style: TextStyle(
                                color: textMainColor,
                                fontFamily: "NotoSans",
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            Icon(
                              Icons.play_arrow_rounded,
                              color: textMainColor,
                              size: 25,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingItem {
  final String label;
  final Widget page;

  SettingItem({
    required this.label,
    required this.page,
  });
}
