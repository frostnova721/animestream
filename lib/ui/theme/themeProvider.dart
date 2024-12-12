import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/data/theme.dart';
import 'package:animestream/ui/theme/themes.dart';
import 'package:animestream/ui/theme/types.dart';
import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  AnimeStreamTheme _theme = appTheme;

  bool _isDark = currentUserSettings?.darkMode ?? false;

  ThemeItem _themeItem = activeThemeItem;

  AnimeStreamTheme get theme => _theme;

  bool get isDark => _isDark;

  ThemeItem get themeItem => _themeItem;

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

    getTheme().then((id) {
      final theme = availableThemes.firstWhere((thm) => thm.id == id, orElse: () => availableThemes[0]);

      if (dark) {
        appTheme = AnimeStreamTheme(
          accentColor: theme.theme.accentColor,
          backgroundColor:
              (currentUserSettings?.amoledBackground ?? false) ? Colors.black : theme.theme.backgroundColor,
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
    });
  }

  set themeItem(ThemeItem ti) {
    activeThemeItem = ti;
  }

  void applyTheme(AnimeStreamTheme t) {
    theme = t;
  }

  void applyThemeMode(bool dark) {
    isDark = dark;
  }

  void justRefresh() {
    notifyListeners();
  }
}
