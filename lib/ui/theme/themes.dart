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

/**Amethyst*/
final amethyst = AnimeStreamTheme(
  accentColor: Color(0xff6a3b76),
  backgroundColor: Color(0xff1a1119),
  backgroundSubColor: Color.fromARGB(255, 65, 37, 53),
  textMainColor: Color(0xfffdf0e6),    // Slightly softened white
  textSubColor: Color(0xffe7c3bf),
  modalSheetBackgroundColor: Color(0xff1e0620),
  onAccent: Color(0xfffbf0e8),
);

final amethystLight = AnimeStreamTheme(
  accentColor: Color(0xff6a3b76),
  backgroundColor: Color(0xfff9efea),
  backgroundSubColor: Color(0xffbb8da3),
  textMainColor: Color(0xff2a1a2a),
  textSubColor: Color(0xff645055),
  modalSheetBackgroundColor: Color(0xfff4e9e4),
  onAccent: Color(0xfff9efea),
);

/**Rizzling Coffee */
final mocha = AnimeStreamTheme(
  accentColor: Color(0xff8C7972),
  backgroundColor: Color(0xff261E18),
  backgroundSubColor: Color(0xff59473C),
  textMainColor: Color(0xffF2F2F2),
  textSubColor: Color(0xFFBFB0AA),
  modalSheetBackgroundColor: Color(0xff261E18),
  onAccent: Color(0xffF2F2F2),
);

final mochaLight = AnimeStreamTheme(
  accentColor: Color(0xff8C7972),
  backgroundColor: Color(0xffF2F2F2),
  backgroundSubColor: Color.fromARGB(255, 190, 154, 131),
  textMainColor: Color(0xff261E18),
  textSubColor: Color.fromARGB(255, 54, 50, 48),
  modalSheetBackgroundColor: Color(0xffF2F2F2),
  onAccent: Color(0xff261E18),
);

final sakuraDark = AnimeStreamTheme(
  accentColor: Color(0xFFFF8FAB),
  backgroundColor: Color(0xFF1A1A1A),
  backgroundSubColor: Color(0xFF332A2D),
  textMainColor: Color(0xFFF8F8F8),
  textSubColor: Color(0xFFBBBBBB),
  modalSheetBackgroundColor: Color(0xFF2D2D2D),
  onAccent: Color(0xFF333333),
);

final sakuraLight = AnimeStreamTheme(
  accentColor: Color(0xFFF06292),
  backgroundColor: Color(0xFFFFF8F8),
  backgroundSubColor: Color(0xFFFCE4EC),
  textMainColor: Color(0xFF333333),
  textSubColor: Color(0xFF767676),
  modalSheetBackgroundColor: Color(0xFFFCECEF),
  onAccent: Color(0xFFFFFFFF),
);

/** List of available themes.
 *
The theme list in UI screen is generated from this list */
List<ThemeItem> availableThemes = [
  ThemeItem(id: 01, name: "Lime Zest", theme: lime, lightVariant: lightLime),
  ThemeItem(id: 02, name: "Monochrome", theme: monochrome, lightVariant: monochromeLight),
  ThemeItem(id: 03, name: "Cold Purple", theme: coldPurple, lightVariant: coldPurpleLight),
  ThemeItem(id: 04, name: "Hot Pink", theme: hotPink, lightVariant: hotPinkLight),
  ThemeItem(id: 05, name: "Amethyst", theme: amethyst, lightVariant: amethystLight),
  ThemeItem(id: 06, name: "Mocha", theme: mocha, lightVariant: mochaLight),
  ThemeItem(id: 07, name: "Sakura", theme: sakuraDark, lightVariant: sakuraLight),
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
