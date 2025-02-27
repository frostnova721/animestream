import 'dart:io';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/data/theme.dart';
import 'package:animestream/ui/theme/themes.dart';
import 'package:animestream/ui/theme/types.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class ThemeProvider with ChangeNotifier {
  AnimeStreamTheme _theme = appTheme;

  bool _isDark = currentUserSettings?.darkMode ?? false;

  ThemeItem _themeItem = activeThemeItem;

  AnimeStreamTheme get theme => _theme;

  bool get isDark => _isDark;

  ThemeItem get themeItem => _themeItem;

  bool _isFullScreen = false;

  bool get isFullScreen => _isFullScreen;

  String _windowTitle = "animestream";

  String get windowTitle => _windowTitle;

  set windowTitle(String newTitle) {
    _windowTitle = newTitle;
    notifyListeners();
  } 

  set isFullScreen(bool fs) {
    _isFullScreen = fs;
    notifyListeners();
  }

  set theme(AnimeStreamTheme selectedTheme) {
    _theme = selectedTheme;

    final dark = currentUserSettings?.darkMode ?? true;

    appTheme = AnimeStreamTheme(
      accentColor: selectedTheme.accentColor,
      //set background color only if dark theme and amoled bg are true, otherwise set respective theme's default bg
      backgroundColor:
          ((currentUserSettings?.amoledBackground ?? false) && dark) ? Colors.black : selectedTheme.backgroundColor,
      backgroundSubColor: selectedTheme.backgroundSubColor,
      textMainColor: selectedTheme.textMainColor,
      textSubColor: selectedTheme.textSubColor,
      modalSheetBackgroundColor: selectedTheme.modalSheetBackgroundColor,
      onAccent: selectedTheme.onAccent,
    );

    notifyListeners();
  }

  set isDark(bool dark) {
    _isDark = dark;
  }

  set themeItem(ThemeItem ti) {
    activeThemeItem = ti;
  }

  void applyTheme(AnimeStreamTheme t) {
    theme = t;
  }

  Future<void> applyThemeMode(bool dark) async {
    isDark = dark;
    final themeId = await getTheme();
    final theme = availableThemes.firstWhere((thm) => thm.id == themeId, orElse: () => availableThemes[0]);

    if (dark) {
      appTheme = AnimeStreamTheme(
        accentColor: theme.theme.accentColor,
        backgroundColor: (currentUserSettings?.amoledBackground ?? false) ? Colors.black : theme.theme.backgroundColor,
        backgroundSubColor: theme.theme.backgroundSubColor,
        textMainColor: theme.theme.textMainColor,
        textSubColor: theme.theme.textSubColor,
        modalSheetBackgroundColor: theme.theme.modalSheetBackgroundColor,
        onAccent: theme.theme.onAccent,
      );
    } else {
      appTheme = AnimeStreamTheme(
        accentColor: theme.lightVariant.accentColor,
        backgroundColor: theme.lightVariant.backgroundColor,
        backgroundSubColor: theme.lightVariant.backgroundSubColor,
        textMainColor: theme.lightVariant.textMainColor,
        textSubColor: theme.lightVariant.textSubColor,
        modalSheetBackgroundColor: theme.lightVariant.modalSheetBackgroundColor,
        onAccent: theme.lightVariant.onAccent,
      );
    }

    notifyListeners();
  }

  void justRefresh() {
    notifyListeners();
  }

  Future<void> setFullScreen(bool fs) async {
    if (Platform.isAndroid) return;
      await windowManager.setFullScreen(fs);
    isFullScreen = fs;
  }
}
