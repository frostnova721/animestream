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
    SettingItem(label: "Theme", page: ThemeSetting()),
    SettingItem(label: "Player", page: PlayerSetting())
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top,
        ),
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
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => items[index].page,
                          ));
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
