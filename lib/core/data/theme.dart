import 'package:animestream/ui/theme/themes.dart';
import 'package:animestream/ui/theme/types.dart';
import 'package:hive/hive.dart';

Future<AnimeStreamTheme> getTheme() async {
  var box = await Hive.openBox("animestream");
  if(!box.isOpen) {
    box = await Hive.openBox("animestream");
  }
  Map<dynamic, dynamic> selectedTheme = box.get('theme') ?? {};
  if(selectedTheme.isEmpty) selectedTheme = lime.toMap();
  final classed = AnimeStreamTheme.fromMap(selectedTheme);
  await box.close();
  return classed;
}

Future<void> setTheme(AnimeStreamTheme theme) async {
   var box = await Hive.openBox("animestream");
  if(!box.isOpen) {
    box = await Hive.openBox("animestream");
  }
  final classifiedInfo = theme.toMap();
  await box.put('theme', classifiedInfo);
  await box.close();
  return;
}