import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/data/hive.dart';
import 'package:animestream/core/data/types.dart';
import 'package:animestream/core/database/database.dart';
import 'package:hive/hive.dart';

/// Retruns an object of [AnimeSpecificPreference] if it exists!
Future<AnimeSpecificPreference?> getAnimeSpecificPreference(String anilistId) async {
  //just handle anilist
  if (currentUserSettings?.database != Databases.anilist) return null;

  var box = await Hive.openBox("animeInfo");
  if (!box.isOpen) {
    box = await Hive.openBox("animeInfo");
  }

  String? manSearch, provider;
  Map<dynamic, dynamic>? lastWatch;

  final Map<dynamic, dynamic> asp = await box.get(HiveKey.animeSpecificPreference.name) ?? {};
  if (asp.isEmpty) {
    print("EMPTY MAP 'animeSpecificPreference'");
  }

  final Map<String, dynamic> item = Map.castFrom(asp[anilistId] ?? {});
  manSearch = item["manualSearchQuery"];
  lastWatch = item['lastWatchDuration'];
  provider = item['preferredProvider'];
  print(item);

  await box.close();

  return AnimeSpecificPreference(
      lastWatchDuration: lastWatch, manualSearchQuery: manSearch, preferredProvider: provider);
}

Future<void> saveAnimeSpecificPreference(String anilistId, AnimeSpecificPreference preference) async {
  Map<dynamic, dynamic> map = Map.castFrom(await getVal(HiveKey.animeSpecificPreference, boxName: "animeInfo") ?? {});

  // print(map);

  final item = map[anilistId] ?? {};

  preference.toMap().forEach((k,v) {
    if(item[k] == null) {
      item[k] = v;
    }
  });

  map[anilistId] = item;

  Map<dynamic, dynamic> filteredMap = map;

  if (map.length > 40) {
    List<MapEntry<dynamic, dynamic>> entries = map.entries.toList();
    entries = entries.sublist(0, 40);
    filteredMap = Map.fromEntries(entries);
  }

  await storeVal(HiveKey.animeSpecificPreference, filteredMap, boxName: "animeInfo");
}