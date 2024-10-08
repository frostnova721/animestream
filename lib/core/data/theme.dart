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

//saves the theme
Future<void> setTheme(int themeId) async {
  var box = await Hive.openBox("animestream");
  if (!box.isOpen) {
    box = await Hive.openBox("animestream");
  }
  // final classifiedInfo = theme.toMap();
  await box.put('theme', themeId);
  // final selectedTheme = availableThemes.where((i) => i.id == themeId).toList()[0].theme;
  // final dark = currentUserSettings?.darkMode ?? true;
  // appTheme = AnimeStreamTheme(
  //   accentColor: selectedTheme.accentColor,
  //   //set background color only if dark theme and amoled bg are true, otherwise set respective theme's default bg
  //   backgroundColor: ((currentUserSettings?.amoledBackground ?? false) && dark) ? Colors.black : (dark ? darkModeValues.backgroundColor : lightModeValues.backgroundColor),
  //   backgroundSubColor: dark ? darkModeValues.backgroundSubColor : lightModeValues.backgroundSubColor,
  //   textMainColor: dark ? darkModeValues.textMainColor : lightModeValues.textMainColor,
  //   textSubColor: dark ? darkModeValues.textSubColor : lightModeValues.textSubColor,
  //   modalSheetBackgroundColor: dark ? darkModeValues.modalSheetBackgroundColor : lightModeValues.modalSheetBackgroundColor,
  // );
  await box.close();
  return;
}
