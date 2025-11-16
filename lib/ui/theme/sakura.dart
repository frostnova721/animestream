import 'package:animestream/ui/theme/types.dart';
import 'package:flutter/material.dart';

class Sakura implements ThemeItem {
  @override
  int get id => 07;

  @override
  bool get dev => false;

  @override
  AnimeStreamTheme get lightVariant => AnimeStreamTheme(
        accentColor: Color(0xFFF06292),
        backgroundColor: Color(0xFFFFF8F8),
        backgroundSubColor: Color(0xFFFCE4EC),
        textMainColor: Color(0xFF333333),
        textSubColor: Color(0xFF767676),
        modalSheetBackgroundColor: Color(0xFFFCECEF),
        onAccent: Color(0xFFFFFFFF),
      );

  @override
  String get name => "Sakura";

  @override
  AnimeStreamTheme get theme => AnimeStreamTheme(
        accentColor: Color(0xFFFF8FAB),
        backgroundColor: Color(0xFF1A1A1A),
        backgroundSubColor: Color(0xFF332A2D),
        textMainColor: Color(0xFFF8F8F8),
        textSubColor: Color(0xFFBBBBBB),
        modalSheetBackgroundColor: Color.fromARGB(255, 31, 31, 31),
        onAccent: Color(0xFF333333),
      );
}
