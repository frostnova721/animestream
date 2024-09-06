import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/data/settings.dart';
import 'package:animestream/core/data/types.dart';
import 'package:animestream/ui/theme/themes.dart';
import 'package:animestream/ui/theme/types.dart';
import 'package:hive/hive.dart';

Future<int> getTheme() async {
  var box = await Hive.openBox("animestream");
  if (!box.isOpen) {
    box = await Hive.openBox("animestream");
  }
  dynamic selectedThemeId = box.get('theme', defaultValue: 01) ?? 01;
  if (selectedThemeId == null || !(selectedThemeId is int)) selectedThemeId = 01;
  // final classed = AnimeStreamTheme.fromMap(selectedTheme);
  await box.close();
  return selectedThemeId;
}

Future<void> setThemeMode(bool isDark) async {
  await Settings().writeSettings(SettingsModal(darkMode: isDark));
  if (isDark) {
    appTheme = AnimeStreamTheme(
      accentColor: appTheme!.accentColor,
      backgroundColor: darkModeValues.backgroundColor,
      backgroundSubColor: darkModeValues.backgroundSubColor,
      textMainColor: darkModeValues.textMainColor,
      textSubColor: appTheme!.textSubColor,
      modalSheetBackgroundColor: darkModeValues.modalSheetBackgroundColor,
    );
  } else {
    appTheme = AnimeStreamTheme(
      accentColor: appTheme!.accentColor,
      backgroundColor: lightModeValues.backgroundColor,
      backgroundSubColor: lightModeValues.backgroundSubColor,
      textMainColor: lightModeValues.textMainColor,
      textSubColor: appTheme!.textSubColor,
      modalSheetBackgroundColor: lightModeValues.modalSheetBackgroundColor,
    );
  }
  return;
}

Future<void> setTheme(int themeId) async {
  var box = await Hive.openBox("animestream");
  if (!box.isOpen) {
    box = await Hive.openBox("animestream");
  }
  // final classifiedInfo = theme.toMap();
  await box.put('theme', themeId);
  appTheme = availableThemes.where((i) => i.id == themeId).toList()[0].theme;
  await box.close();
  return;
}
