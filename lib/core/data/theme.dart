import 'package:hive/hive.dart';

Future<int> getTheme() async {
  var box = await Hive.openBox("animestream");
  if(!box.isOpen) {
    box = await Hive.openBox("animestream");
  }
  dynamic selectedThemeId = box.get('theme', defaultValue: 01) ?? 01;
  if(selectedThemeId == null || !(selectedThemeId is int)) selectedThemeId = 01;
  // final classed = AnimeStreamTheme.fromMap(selectedTheme);
  await box.close();
  return selectedThemeId;
}

Future<void> setTheme(int themeId) async {
   var box = await Hive.openBox("animestream");
  if(!box.isOpen) {
    box = await Hive.openBox("animestream");
  }
  // final classifiedInfo = theme.toMap();
  await box.put('theme', themeId);
  await box.close();
  return;
}