import 'package:animestream/ui/theme/themes.dart';
import 'package:flutter/material.dart';

class AnimeStreamTheme {
  Color backgroundColor;
  Color accentColor;
  Color textMainColor;
  Color textSubColor;
  Color backgroundSubColor;
  Color modalSheetBackgroundColor;

  AnimeStreamTheme({
    required this.accentColor,
    required this.backgroundColor,
    required this.backgroundSubColor,
    required this.textMainColor,
    required this.textSubColor,
    required this.modalSheetBackgroundColor,
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
    };
  }
}
