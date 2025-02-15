import 'dart:io';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/data/theme.dart';
import 'package:animestream/ui/theme/themes.dart';
import 'package:animestream/ui/theme/types.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:window_size/window_size.dart';

class ThemeProvider with ChangeNotifier {
  AnimeStreamTheme _theme = appTheme;

  bool _isDark = currentUserSettings?.darkMode ?? false;

  ThemeItem _themeItem = activeThemeItem;

  AnimeStreamTheme get theme => _theme;

  bool get isDark => _isDark;

  ThemeItem get themeItem => _themeItem;

  bool _isFullScreen = false;

  bool get isFullScreen => _isFullScreen;

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

  bool _isInitiallyMaximized = false;

  Offset _prevPos = Offset.zero; // The offset of window before entering fullscreen

  // The size of window before entering fullscreen, set to 1280x720 just as a placeholder value
  // and will be overriden once fullscreen is entered!
  Size _prevSize = Size(1280, 720);

  Future<void> setFullScreen(bool fs) async {
    if (Platform.isAndroid) return;
    if (currentUserSettings?.useFramelessWindow ?? true) {
      if (fs) {
        _isInitiallyMaximized = await windowManager.isMaximized();
        await windowManager.unmaximize();
        final info = await getCurrentScreen();
        _prevPos = await windowManager.getPosition();
        _prevSize = await windowManager.getSize();
        if (info != null) {
          await windowManager.setPosition(Offset.zero);
          await windowManager.setSize(
            Size(
              info.frame.width / info.scaleFactor,
              info.frame.height / info.scaleFactor,
            ),
          );
        }
      } else {
        if (_isInitiallyMaximized) {
          windowManager.maximize();
        } else {
          await windowManager.setPosition(_prevPos);
          await windowManager.setSize(_prevSize);
        }
      }
    } else {
      await windowManager.setFullScreen(fs); // Using default fs cus the border messes with the sizing
    }
    isFullScreen = fs;
  }
}
