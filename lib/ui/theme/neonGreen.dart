import 'package:animestream/ui/theme/types.dart';
import 'package:flutter/material.dart';

class NeonGreen implements ThemeItem {
  @override
  int get id => 08;

  @override
  bool get dev => false;

  @override
  AnimeStreamTheme get lightVariant => AnimeStreamTheme(
        accentColor: Color(0xff00c896),
        backgroundColor: Color(0xfff5f9fc),
        modalSheetBackgroundColor: Color(0xffffffff),
        backgroundSubColor: Color(0xffe0eaf2),
        textMainColor: Color(0xff102a39),
        textSubColor: Color(0xff5d717f),
        onAccent: Colors.white,
      );

  @override
  String get name => "Neon Green";

  @override
  AnimeStreamTheme get theme => AnimeStreamTheme(
        accentColor: Color(0xff27e9b5),
        backgroundColor: Color(0xff051824),
        modalSheetBackgroundColor: Color(0xff162936),
        backgroundSubColor: Color(0xff2a3e4d),
        textMainColor: Color(0xffffffff),
        textSubColor: Color(0xffb0b8c1),
        onAccent: Colors.black,
      );
}
