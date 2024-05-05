import 'package:animestream/ui/theme/themes.dart';
import 'package:flutter/material.dart';

class AnimeStreamTheme {
  Color backgroundColor;
  Color accentColor;
  Color textMainColor;
  Color textSubColor;
  Color backgroundSubColor;

  AnimeStreamTheme({
    required this.accentColor,
    required this.backgroundColor,
    required this.backgroundSubColor,
    required this.textMainColor,
    required this.textSubColor,
    // required this.modalSheetBackground
  });

  factory AnimeStreamTheme.fromMap(Map<dynamic, dynamic> map) {
    return AnimeStreamTheme(
      accentColor: Color(int.tryParse(map['accentColor'], radix: 16) ??
          int.parse(lime.accentColor.value.toRadixString(16))),
      textMainColor: Color(int.tryParse(map['textMainColor'], radix: 16) ??
          int.parse(lime.textMainColor.value.toRadixString(16))),
      textSubColor: Color(int.tryParse(map['textSubColor'], radix: 16) ??
          int.parse(lime.textSubColor.value.toRadixString(16))),
      backgroundColor: Color(int.tryParse(map['backgroundColor'], radix: 16) ??
          int.parse(lime.backgroundColor.value.toRadixString(16))),
          backgroundSubColor: Color(int.tryParse(map['backgroundSubColor'], radix: 16) ??
          int.parse(lime.backgroundSubColor.value.toRadixString(16))),
    );
  }

  Map<String, String> toMap() {
    return {
      'accentColor': accentColor.value.toRadixString(16),
      'backgroundColor': backgroundColor.value.toRadixString(16),
      'backgroundSubColor': backgroundSubColor.value.toRadixString(16),
      'textMainColor': textMainColor.value.toRadixString(16),
      'textSubColor': textSubColor.value.toRadixString(16),
    };
  }
}
