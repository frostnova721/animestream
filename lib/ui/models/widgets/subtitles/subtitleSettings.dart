// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:animestream/core/commons/extensions.dart';

class SubtitleSettings {
  final Color textColor;
  final Color strokeColor;
  final Color backgroundColor;

  final String? fontFamily;

  final double strokeWidth;
  final double fontSize;
  final double bottomMargin;
  final double backgroundTransparency;

  final bool bold;
  final bool enableShadows;

  const SubtitleSettings({
    this.backgroundColor = Colors.black,
    this.backgroundTransparency = 0,
    this.bottomMargin = 30,
    this.fontSize = 24,
    this.strokeColor = Colors.black,
    this.strokeWidth = 2,
    this.textColor = Colors.white,
    this.fontFamily = "Rubik",
    this.bold = false,
    this.enableShadows = true,
  });

  SubtitleSettings copyWith({
    Color? textColor,
    Color? strokeColor,
    Color? backgroundColor,
    String? fontFamily,
    double? strokeWidth,
    double? fontSize,
    double? bottomMargin,
    double? backgroundTransparency,
    bool? bold,
    bool? enableShadows,
  }) {
    return SubtitleSettings(
      textColor: textColor ?? this.textColor,
      strokeColor: strokeColor ?? this.strokeColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fontFamily: fontFamily ?? this.fontFamily,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      fontSize: fontSize ?? this.fontSize,
      bottomMargin: bottomMargin ?? this.bottomMargin,
      backgroundTransparency: backgroundTransparency ?? this.backgroundTransparency,
      bold: bold ?? this.bold,
      enableShadows: enableShadows ?? this.enableShadows,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'textColor': textColor.toInt(),
      'strokeColor': strokeColor.toInt(),
      'backgroundColor': backgroundColor.toInt(),
      'fontFamily': fontFamily,
      'strokeWidth': strokeWidth,
      'fontSize': fontSize,
      'bottomMargin': bottomMargin,
      'backgroundTransparency': backgroundTransparency,
      'bold': bold,
      'enableShadows': enableShadows,
    };
  }

  factory SubtitleSettings.fromMap(Map<dynamic, dynamic> map) {
    return SubtitleSettings(
        textColor: Color(map['textColor'] as int? ?? Colors.white.toInt()),
        strokeColor: Color(map['strokeColor'] as int? ?? Colors.black.toInt()),
        backgroundColor: Color((map['backgroundColor'] ?? Colors.black.toInt()) as int),
        fontFamily: map['fontFamily'] != null ? map['fontFamily'] as String : "Rubik",
        strokeWidth: (map['strokeWidth'] ?? 1.1) as double,
        fontSize: (map['fontSize'] ?? 24) as double,
        bottomMargin: (map['bottomMargin'] ?? 30) as double,
        backgroundTransparency: (map['backgroundTransparency'] ?? 0) as double,
        bold: (map['bold'] ?? false) as bool,
        enableShadows: (map['enableShadows'] ?? true) as bool);
  }

  String toJson() => json.encode(toMap());

  factory SubtitleSettings.fromJson(String source) =>
      SubtitleSettings.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'SubtitleSettings(textColor: $textColor, strokeColor: $strokeColor, backgroundColor: $backgroundColor, fontFamily: $fontFamily, strokeWidth: $strokeWidth, fontSize: $fontSize, bottomMargin: $bottomMargin, backgroundTransparency: $backgroundTransparency, bold: $bold, enableShadows: $enableShadows)';
  }
}
