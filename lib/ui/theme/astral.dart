import 'package:animestream/ui/theme/types.dart';
import 'package:flutter/material.dart';

/// Warm charcoal and amber theme with a cream light variant.
class Astral implements ThemeItem {
  @override
  int get id => 12;

  @override
  bool get dev => false;

  @override
  AnimeStreamTheme get lightVariant => AnimeStreamTheme(
        accentColor: Color(0xffA34B16),
        backgroundColor: Color(0xffFFF0DA),
        backgroundSubColor: Color(0xffF3D9B8),
        textMainColor: Color(0xff3B2114),
        textSubColor: Color(0xff79533D),
        modalSheetBackgroundColor: Color(0xffFFE6C5),
        onAccent: Color(0xffFFF8EF),
      );

  @override
  String get name => "Astral";

  @override
  AnimeStreamTheme get theme => AnimeStreamTheme(
        accentColor: Color(0xffFFB454),
        backgroundColor: Color(0xff191411),
        backgroundSubColor: Color(0xff28201A),
        textMainColor: Color(0xffF4E8DA),
        textSubColor: Color(0xffBBA896),
        modalSheetBackgroundColor: Color(0xff28201A),
        onAccent: Color(0xff301B00),
      );
}
