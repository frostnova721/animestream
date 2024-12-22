import 'package:animestream/ui/theme/types.dart';
import 'package:flutter/material.dart';

/** this is the default theme */

final lime = AnimeStreamTheme(
  accentColor: Color(0xffCAF979),
  backgroundColor: Color.fromARGB(255, 24, 24, 24),
  backgroundSubColor: Color.fromARGB(255, 36, 36, 36),
  textMainColor: Colors.white,
  textSubColor: Color.fromARGB(255, 180, 180, 180),
  modalSheetBackgroundColor: Color(0xff121212),
  onAccent: Colors.black,
);

final lightLime = AnimeStreamTheme(
  accentColor: Color(0xffcaf979),
  backgroundColor: Colors.white,
  textMainColor: Colors.black,
  textSubColor: Color.fromARGB(255, 82, 82, 82),
  modalSheetBackgroundColor: Colors.white,
  backgroundSubColor: Color.fromARGB(255, 179, 179, 179),
  onAccent: Colors.black,
);

/**monochrome theme preset */

final monochrome = AnimeStreamTheme(
  accentColor: Colors.white,
  backgroundColor: Colors.black,
  backgroundSubColor: Color.fromARGB(255, 36, 36, 36),
  textMainColor: Colors.white,
  textSubColor: Color.fromARGB(255, 180, 180, 180),
  modalSheetBackgroundColor: Color(0xff121212),
  onAccent: Colors.black,
);

final monochromeLight = AnimeStreamTheme(
  accentColor: Colors.black,
  backgroundColor: Colors.white,
  backgroundSubColor: const Color.fromARGB(255, 172, 172, 172),
  textMainColor: Colors.black,
  textSubColor: Colors.black,
  modalSheetBackgroundColor: Colors.white,
  onAccent: Colors.white,
);

/**hotpink accent */

final hotPink = AnimeStreamTheme(
  accentColor: Color.fromARGB(255, 255, 91, 173),
  backgroundColor: Color.fromARGB(255, 24, 24, 24),
  backgroundSubColor: Color.fromARGB(255, 36, 36, 36),
  textMainColor: Colors.white,
  textSubColor: Color.fromARGB(255, 180, 180, 180),
  modalSheetBackgroundColor: Color(0xff121212),
  onAccent: Colors.black,
);

final hotPinkLight = AnimeStreamTheme(
  accentColor: Color.fromARGB(255, 255, 91, 173),
  backgroundColor: Colors.white,
  backgroundSubColor: Color.fromARGB(255, 179, 179, 179),
  textMainColor: Colors.black,
  textSubColor: Color.fromARGB(255, 82, 82, 82),
  modalSheetBackgroundColor: Colors.white,
  onAccent: Colors.white,
);

/**Cold Purple accent */
final coldPurple = AnimeStreamTheme(
  accentColor: Color(0xff9D8ABF),
  backgroundColor: Color.fromARGB(255, 24, 24, 24),
  backgroundSubColor: const Color.fromARGB(255, 36, 36, 36),
  textMainColor: Colors.white,
  textSubColor: Color.fromARGB(255, 180, 180, 180),
  modalSheetBackgroundColor: Color(0xff121212),
  onAccent: Colors.black,
);

final coldPurpleLight = AnimeStreamTheme(
  accentColor: Color(0xff9D8ABF),
  backgroundColor: Colors.white,
  backgroundSubColor: Color.fromARGB(255, 179, 179, 179),
  textMainColor: Colors.black,
  textSubColor: Color.fromARGB(255, 82, 82, 82),
  modalSheetBackgroundColor: Colors.white,
  onAccent: Colors.white,
);

/**SOMETHING NEW */
final midnightBloom = AnimeStreamTheme(
  accentColor: Color(0xff522b5b),
  backgroundColor:  Color.fromARGB(255, 26, 17, 26),
  backgroundSubColor: Color.fromARGB(255, 148, 88, 120),
  textMainColor: Color(0xfffbe4d8),
  textSubColor: Color(0xffdfb6b2),
  modalSheetBackgroundColor: Color(0xff190019),
  onAccent: Color(0xfffbe4d8),
);

final midnightBloomLight = AnimeStreamTheme(
  accentColor: Color(0xff522b5b),
  backgroundColor:  Color(0xfffbe4d8),
  backgroundSubColor: Color.fromARGB(255, 206, 150, 180),
  textMainColor: Color(0xff190019),
  textSubColor: Color.fromARGB(255, 80, 65, 64),
  modalSheetBackgroundColor: Color(0xfffbe4d8),
  onAccent: Color(0xfffbe4d8),
);

//try this pink color! #bc0150, sub color: 18181d

List<ThemeItem> availableThemes = [
  ThemeItem(id: 01, name: "Lime Zest", theme: lime, lightVariant: lightLime),
  ThemeItem(id: 02, name: "Monochrome", theme: monochrome, lightVariant: monochromeLight),
  ThemeItem(id: 03, name: "Cold Purple", theme: coldPurple, lightVariant: coldPurpleLight),
  ThemeItem(id: 04, name: "Hot Pink", theme: hotPink, lightVariant: hotPinkLight),
  ThemeItem(id: 05, name: "Midnight Bloom", theme: midnightBloom, lightVariant: midnightBloomLight)
];

ThemeModeValues lightModeValues = ThemeModeValues(
  textMainColor: Colors.black,
  textSubColor: Color.fromARGB(255, 61, 61, 61),
  backgroundColor: Colors.white,
  backgroundSubColor: Color.fromARGB(255, 179, 179, 179),
  modalSheetBackgroundColor: Colors.white,
);

ThemeModeValues darkModeValues = ThemeModeValues(
  backgroundColor: Color.fromARGB(255, 24, 24, 24),
  backgroundSubColor: const Color.fromARGB(255, 36, 36, 36),
  textMainColor: Colors.white,
  textSubColor: Color.fromARGB(255, 180, 180, 180),
  modalSheetBackgroundColor: Color(0xff121212),
);
