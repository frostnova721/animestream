import 'package:flutter/material.dart';

class FloatyBottomBarController {
  final int length;
  final List<int> nonViewIndices;
  final int animDuration;
  // late int currentIndex;

  ValueNotifier<int> currentIndexNotifier;

  int get currentIndex => currentIndexNotifier.value;

  set currentIndex(int index) {
    if (!nonViewIndices.contains(index)) currentIndexNotifier.value = index;
  }

  FloatyBottomBarController({
    required this.length,
    this.nonViewIndices = const [],
    this.animDuration = 200,
  }) : currentIndexNotifier = ValueNotifier<int>(0);
}