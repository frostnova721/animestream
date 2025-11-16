import 'package:animestream/ui/theme/types.dart';
import 'package:flutter/material.dart';

class Amethyst implements ThemeItem {
  @override
  int get id => 05;

  @override
  bool get dev => false;

  @override
  AnimeStreamTheme get lightVariant => AnimeStreamTheme(
        accentColor: Color(0xff6a3b76),
        backgroundColor: Color(0xfff9efea),
        backgroundSubColor: Color(0xffbb8da3),
        textMainColor: Color(0xff2a1a2a),
        textSubColor: Color(0xff645055),
        modalSheetBackgroundColor: Color(0xfff4e9e4),
        onAccent: Color(0xfff9efea),
      );

  @override
  String get name => "Amethyst";

  @override
  AnimeStreamTheme get theme => AnimeStreamTheme(
        accentColor: Color(0xff6a3b76),
        backgroundColor: Color(0xff1a1119),
        backgroundSubColor: Color.fromARGB(255, 65, 37, 53),
        textMainColor: Color(0xfffdf0e6), // Slightly softened white
        textSubColor: Color(0xffe7c3bf),
        modalSheetBackgroundColor: Color(0xff1e0620),
        onAccent: Color(0xfffbf0e8),
      );
}
