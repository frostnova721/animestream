import 'package:animestream/ui/theme/types.dart';
import 'package:flutter/material.dart';

class Monochrome implements ThemeItem {
  @override
  int get id => 02;

  @override
  bool get dev => false;

  @override
  AnimeStreamTheme get lightVariant => AnimeStreamTheme(
        accentColor: Colors.black,
        backgroundColor: Colors.white,
        backgroundSubColor: const Color.fromARGB(255, 172, 172, 172),
        textMainColor: Colors.black,
        textSubColor: Colors.black,
        modalSheetBackgroundColor: Colors.white,
        onAccent: Colors.white,
      );

  @override
  String get name => "Monochrome";

  @override
  AnimeStreamTheme get theme => AnimeStreamTheme(
        accentColor: Colors.white,
        backgroundColor: Colors.black,
        backgroundSubColor: Color.fromARGB(255, 36, 36, 36),
        textMainColor: Colors.white,
        textSubColor: Color.fromARGB(255, 180, 180, 180),
        modalSheetBackgroundColor: Color(0xff121212),
        onAccent: Colors.black,
      );
}
