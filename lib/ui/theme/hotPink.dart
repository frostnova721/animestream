import 'package:animestream/ui/theme/types.dart';
import 'package:flutter/material.dart';

class HotPink implements ThemeItem {
  @override
  int get id => 04;

  @override
  AnimeStreamTheme get lightVariant => AnimeStreamTheme(
        accentColor: Color.fromARGB(255, 255, 91, 173),
        backgroundColor: Colors.white,
        backgroundSubColor: Color.fromARGB(255, 179, 179, 179),
        textMainColor: Colors.black,
        textSubColor: Color.fromARGB(255, 82, 82, 82),
        modalSheetBackgroundColor: Colors.white,
        onAccent: Colors.white,
      );

  @override
  String get name => "Hot Pink";

  @override
  AnimeStreamTheme get theme => AnimeStreamTheme(
        accentColor: Color.fromARGB(255, 255, 91, 173),
        backgroundColor: Color.fromARGB(255, 24, 24, 24),
        backgroundSubColor: Color.fromARGB(255, 36, 36, 36),
        textMainColor: Colors.white,
        textSubColor: Color.fromARGB(255, 180, 180, 180),
        modalSheetBackgroundColor: Color(0xff121212),
        onAccent: Colors.black,
      );
}
