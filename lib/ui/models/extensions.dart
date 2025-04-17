import 'package:flutter/material.dart';

extension ColorExtensions on Color {
  String toHexString() {
    final alpha = (this.a * 255).toInt();
    final red = (this.r * 255).toInt();
    final green = (this.g * 255).toInt();
    final blue = (this.b * 255).toInt();

    return "${alpha.toRadixString(16).padLeft(2,'0')}${red.toRadixString(16).padLeft(2,'0')}${green.toRadixString(16).padLeft(2,'0')}${blue.toRadixString(16).padLeft(2,'0')}";
  }

  /**Returns the integer representation of the color */
  int toInt() {
    final alpha = (this.a * 255).toInt();
    final red = (this.r * 255).toInt();
    final green = (this.g * 255).toInt();
    final blue = (this.b * 255).toInt();
    return (alpha << 24) | (red << 16) | (green << 8) | blue;
  }
}