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

  getCurrentTheme() {
    getTheme().then((value) => setState(() {
          currentTheme = value;
        }));
  }

  applyTheme(AnimeStreamTheme theme) async {
    await setTheme(theme);
    floatingSnackBar(context, "All set! restart the app to apply the theme");
  }

  AnimeStreamTheme? currentTheme;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Padding(
        padding: pagePadding(context),
        child: Column(
          children: [
            topRow(context, "Themes"),
            Container(
              padding: EdgeInsets.only(left: 10, right: 10, top: 30),
              child: currentTheme != null
                  ? Column(
                      children: [
                        _themeItem("Dark Ash - Lime", lime),
                        _themeItem("Monochrome", monochrome),
                        _themeItem("Hot Pink", hotPink),
                        _themeItem("Cold Purple", coldPurple)
                      ],
                    )
                  : Container(),
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
        //check if selected theme is same as current theme
        if (currentTheme?.accentColor != theme.accentColor) {
          await applyTheme(theme);
          setState(() {
            currentTheme = theme;
          });
        }
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.only(left: 10, right: 10),
        color: currentTheme?.accentColor == theme.accentColor
            ? currentTheme?.backgroundSubColor
            : Colors.transparent,
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
                border: Border.all(color: Colors.black, width: 3),
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
