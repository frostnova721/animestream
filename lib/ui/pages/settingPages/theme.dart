import 'package:animestream/core/data/theme.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:animestream/ui/theme/themes.dart';
import 'package:animestream/ui/theme/types.dart';
import 'package:flutter/material.dart';

class ThemeSetting extends StatefulWidget {
  const ThemeSetting({super.key});

  @override
  State<ThemeSetting> createState() => _ThemeSettingState();
}

class _ThemeSettingState extends State<ThemeSetting> {

  @override
  void initState() {
    super.initState();
    getCurrentTheme();
    
  }

  getCurrentTheme() async {
    getTheme().then((value) => currentTheme = value);
  }

  applyTheme(AnimeStreamTheme theme) async {
    await setTheme(theme);
    await floatingSnackBar(context, "All set! restart the app to apply the theme");
  }

  AnimeStreamTheme? currentTheme;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: Column(
          children: [
            topRow(context, "Themes"),
            Container(
              padding: EdgeInsets.only(left: 10, right: 10, top: 30),
              child: Column(
                children: [
                  _themeItem("Dark Ash - Lime", lime),
                  _themeItem("Monochrome", monochrome),
                  _themeItem("Hot Pink", hotPink),
                  _themeItem("Cold Purple", coldPurple)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InkWell _themeItem(String name, AnimeStreamTheme theme) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        await applyTheme(theme);
      },
      child: Container(
        padding: EdgeInsets.only(left: 10, right: 10),
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "$name",
              style: textStyle(),
            ),
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: theme.accentColor,
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
