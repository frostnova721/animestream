import 'package:flutter/material.dart';

enum ScreenType {
  small,
  medium,
  expanded,
  large,
}

extension ScreenTypeExtension on BuildContext {
  double get width => MediaQuery.of(this).size.width;

  ScreenType get screenType {
    switch (width) {
      case double w when w < 600:
        return ScreenType.small;
      case double w when w >= 600 && w < 840:
        return ScreenType.medium;
      case double w when w >= 840 && w < 1200:
        return ScreenType.expanded;
      default:
        return ScreenType.large;
    }
  }
} 