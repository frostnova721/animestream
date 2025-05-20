import 'package:animestream/ui/theme/types.dart';
import 'package:flutter/material.dart';

/// The default theme
class LimeZest implements ThemeItem {
  @override
  int get id => 00;

   @override
  String get name => "Lime Zest";

  @override
  AnimeStreamTheme get lightVariant => AnimeStreamTheme(
        accentColor: Color(0xffcaf979),
        backgroundColor: Colors.white,
        textMainColor: Colors.black,
        textSubColor: Color.fromARGB(255, 82, 82, 82),
        modalSheetBackgroundColor: Colors.white,
        backgroundSubColor: Color.fromARGB(255, 179, 179, 179),
        onAccent: Colors.black,
      );

  @override
  AnimeStreamTheme get theme => AnimeStreamTheme(
        accentColor: Color(0xffCAF979),
        backgroundColor: Color.fromARGB(255, 24, 24, 24),
        backgroundSubColor: Color.fromARGB(255, 36, 36, 36),
        textMainColor: Colors.white,
        textSubColor: Color.fromARGB(255, 180, 180, 180),
        modalSheetBackgroundColor: Color(0xff121212),
        onAccent: Colors.black,
      );
}
