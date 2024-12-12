import 'package:animestream/ui/theme/themes.dart';
import 'package:flutter/material.dart';

class ThemeItem {
  final String name;
  final AnimeStreamTheme theme;
  final AnimeStreamTheme lightVariant;
  final int id;

  ThemeItem({
    required this.id,
    required this.name,
    required this.theme,
    required this.lightVariant,
  });
}

class AnimeStreamTheme {
  //core theme
  Color backgroundColor;               //background
  Color accentColor;                   //accent
  Color textMainColor;                 //for main texts
  Color textSubColor;                  //for description|sub texts
  Color backgroundSubColor;            //for card tints and some button highlights
  Color modalSheetBackgroundColor;     //for modal sheet (no issue being same as background)
  Color onAccent; 

  AnimeStreamTheme({
    required this.accentColor,
    required this.backgroundColor,
    required this.backgroundSubColor,
    required this.textMainColor,
    required this.textSubColor,
    required this.modalSheetBackgroundColor,
    required this.onAccent,
  });

  //convert map to class
  factory AnimeStreamTheme.fromMap(Map<dynamic, dynamic> map) {
    return AnimeStreamTheme(
      accentColor: Color(int.parse(map['accentColor'] ?? lime.accentColor.value.toRadixString(16), radix: 16)),
      textMainColor: Color(int.parse(map['textMainColor'] ?? lime.textMainColor.value.toRadixString(16), radix: 16)),
      textSubColor: Color(int.parse(map['textSubColor'] ?? lime.textSubColor.value.toRadixString(16), radix: 16)),
      backgroundColor:
          Color(int.parse(map['backgroundColor'] ?? lime.backgroundColor.value.toRadixString(16), radix: 16)),
      backgroundSubColor:
          Color(int.parse(map['backgroundSubColor'] ?? lime.backgroundSubColor.value.toRadixString(16), radix: 16)),
      modalSheetBackgroundColor: Color(int.parse(
          map['modalSheetBackgroundColor'] ?? lime.modalSheetBackgroundColor.value.toRadixString(16),
          radix: 16)),
          onAccent: Color(int.parse(map['onAccent'] ?? lime.onAccent.value.toRadixString(16), radix: 16)),
    );
  }

  //convert class to map
  Map<String, String> toMap() {
    return {
      'accentColor': accentColor.value.toRadixString(16),
      'backgroundColor': backgroundColor.value.toRadixString(16),
      'backgroundSubColor': backgroundSubColor.value.toRadixString(16),
      'textMainColor': textMainColor.value.toRadixString(16),
      'textSubColor': textSubColor.value.toRadixString(16),
      'modalSheetBackgroundColor': modalSheetBackgroundColor.value.toRadixString(16),
      'onAccent': onAccent.value.toRadixString(16),
    };
  }
}

class ThemeModeValues {
  Color textMainColor;
  Color textSubColor;
  Color backgroundColor;
  Color backgroundSubColor;
  Color modalSheetBackgroundColor;

  ThemeModeValues(
      {required this.backgroundColor,
      required this.textMainColor,
      required this.textSubColor,
      required this.backgroundSubColor,
      required this.modalSheetBackgroundColor});
}
