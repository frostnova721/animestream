import 'package:animestream/ui/theme/types.dart';
import 'package:flutter/material.dart';

class Mocha implements ThemeItem {
  @override
  int get id => 06;

  @override
  AnimeStreamTheme get lightVariant => AnimeStreamTheme(
        accentColor: Color(0xff8C7972),
        backgroundColor: Color(0xffF2F2F2),
        backgroundSubColor: Color.fromARGB(255, 190, 154, 131),
        textMainColor: Color(0xff261E18),
        textSubColor: Color.fromARGB(255, 54, 50, 48),
        modalSheetBackgroundColor: Color(0xffF2F2F2),
        onAccent: Color(0xff261E18),
      );

  @override
  String get name => "Mocha";

  @override
  AnimeStreamTheme get theme => AnimeStreamTheme(
        accentColor: Color(0xff8C7972),
        backgroundColor: Color(0xff261E18),
        backgroundSubColor: Color(0xff59473C),
        textMainColor: Color(0xffF2F2F2),
        textSubColor: Color(0xFFBFB0AA),
        modalSheetBackgroundColor: Color(0xff261E18),
        onAccent: Color(0xffF2F2F2),
      );
}
