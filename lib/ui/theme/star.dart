import 'package:animestream/ui/theme/types.dart';
import 'package:flutter/material.dart';

class Star implements ThemeItem {
  @override
  int get id => 09;

  @override
  AnimeStreamTheme get lightVariant => AnimeStreamTheme(
      accentColor: Color(0xFFFBC02D),
      backgroundColor: Color(0xFFFAF8F0),
      backgroundSubColor: Color.fromARGB(255, 255, 239, 168),
      textMainColor: Color(0xFF3A3A3A),
      textSubColor: Color.fromARGB(255, 95, 92, 88),
      modalSheetBackgroundColor: Color(0xFFFFFFFF),
      onAccent: Color(0xFF000000),
    );

  @override
  String get name => "Star";

  @override
  AnimeStreamTheme get theme => AnimeStreamTheme(
        accentColor: Color(0xFFFBC02D),
        backgroundColor: Color(0xFF272727),
        backgroundSubColor: Color(0xFF1A1A1A),
        textMainColor: Color(0xFFFFFFFF),
        textSubColor: Color.fromARGB(255, 190, 190, 190),
        modalSheetBackgroundColor: Color(0xFF121212),
        onAccent: Color(0xFF000000),
      );
}
