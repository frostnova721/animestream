import 'package:hive/hive.dart';

Future<int> getTheme() async {
  var box = await Hive.openBox("animestream");
  if (!box.isOpen) {
    box = await Hive.openBox("animestream");
  }
  dynamic selectedThemeId = box.get('theme', defaultValue: 01) ?? 01;
  if (selectedThemeId == null || !(selectedThemeId is int)) selectedThemeId = 01;
  await box.close();
  return selectedThemeId;
}

//saves the theme
Future<void> setTheme(int themeId) async {
  var box = await Hive.openBox("animestream");
  if (!box.isOpen) {
    box = await Hive.openBox("animestream");
  }
  await box.put('theme', themeId);
  await box.close();
  return;
}
