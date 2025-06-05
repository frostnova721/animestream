import 'dart:io';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:flutter/material.dart';

void showPopup({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool? showSheetHandle,
  Color? backgroundColor,
  bool isScrollControlledSheet = false,
}) {
  final isDesktop = Platform.isWindows;

  if (isDesktop) {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (ctx) => Dialog(
        backgroundColor: backgroundColor ?? appTheme.modalSheetBackgroundColor,
        child: builder(ctx),
      ),
    );
    return;
  } else {
    showModalBottomSheet(
        context: context,
        showDragHandle: showSheetHandle,
        backgroundColor: backgroundColor ?? appTheme.modalSheetBackgroundColor,
        useRootNavigator: false,
        isScrollControlled: isScrollControlledSheet,
        builder: builder);
  }
}
