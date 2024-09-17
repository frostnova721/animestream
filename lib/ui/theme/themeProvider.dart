import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/ui/theme/themes.dart';
import 'package:animestream/ui/theme/types.dart';
import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  AnimeStreamTheme _theme = appTheme;

  bool _isDark = true;

  AnimeStreamTheme get theme => _theme;

  bool get isDark => _isDark;

  set theme(AnimeStreamTheme selectedTheme) {
    _theme = selectedTheme;

    final dark = currentUserSettings?.darkMode ?? true;

    appTheme = AnimeStreamTheme(
      accentColor: selectedTheme.accentColor,
      //set background color only if dark theme and amoled bg are true, otherwise set respective theme's default bg
      backgroundColor: ((currentUserSettings?.amoledBackground ?? false) && dark)
          ? Colors.black
          : (dark ? darkModeValues.backgroundColor : lightModeValues.backgroundColor),
      backgroundSubColor: dark ? darkModeValues.backgroundSubColor : lightModeValues.backgroundSubColor,
      textMainColor: dark ? darkModeValues.textMainColor : lightModeValues.textMainColor,
      textSubColor: dark ? darkModeValues.textSubColor : lightModeValues.textSubColor,
      modalSheetBackgroundColor:
          dark ? darkModeValues.modalSheetBackgroundColor : lightModeValues.modalSheetBackgroundColor,
    );

    notifyListeners();
  }

  set isDark(bool dark) {
    if (dark) {
      appTheme = AnimeStreamTheme(
        accentColor: appTheme.accentColor,
        backgroundColor:
            (currentUserSettings?.amoledBackground ?? false) ? Colors.black : darkModeValues.backgroundColor,
        backgroundSubColor: darkModeValues.backgroundSubColor,
        textMainColor: darkModeValues.textMainColor,
        textSubColor: darkModeValues.textSubColor,
        modalSheetBackgroundColor: darkModeValues.modalSheetBackgroundColor,
      );
    } else {
      appTheme = AnimeStreamTheme(
        accentColor: appTheme.accentColor,
        backgroundColor: lightModeValues.backgroundColor,
        backgroundSubColor: lightModeValues.backgroundSubColor,
        textMainColor: lightModeValues.textMainColor,
        textSubColor: lightModeValues.textSubColor,
        modalSheetBackgroundColor: lightModeValues.modalSheetBackgroundColor,
      );
    }

    notifyListeners();
  }

  void applyTheme(AnimeStreamTheme t) {
    if ((currentUserSettings?.materialTheme ?? false)) {
      theme = t;
    } else {
      print("refreshing...");
      notifyListeners();
    }
  }

  void applyThemeMode(bool dark) {
    isDark = dark;
  }

  void justRefresh() {
    notifyListeners();
  }
}
