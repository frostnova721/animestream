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

  Map<dynamic, dynamic>? lastWatchDuration;
  String? manualSearchString;

  final Map<dynamic, dynamic> lastWatch = await box.get(HiveKey.lastWatchDuration.name) ?? {};
  if (lastWatch.isEmpty) {
    print("EMPTY MAP 'lastWatchDuration'");
  }

  lastWatchDuration = lastWatch[anilistId] ?? null;

  Map<dynamic, dynamic>? manualSearchQuery = await box.get(HiveKey.manualSearches.name);
  if (manualSearchQuery?.isEmpty ?? true) {
    print("EMPTY MAP 'manualSearches'");
  }

  manualSearchString = manualSearchQuery?[anilistId] ?? '';
  if (manualSearchString?.isEmpty ?? true) {
    print("NO QUERY FOR ALTERNATE SEARCHING");
    manualSearchString = null;
  }
  
  await box.close();
  
  return AnimeSpecificPreference(lastWatchDuration: lastWatchDuration, manualSearchQuery: manualSearchString);
}

Future<void> addLastWatchedDuration(String anilistId, Map<int, double> item) async {
  Map<dynamic, dynamic> map = await getVal(HiveKey.lastWatchDuration, boxName: "animeInfo") ?? {};

  print(map);

  map[anilistId] = item;

  Map<dynamic, dynamic> filteredMap = map;

  if (map.length > 40) {
    List<MapEntry<dynamic, dynamic>> entries = map.entries.toList();
    entries = entries.sublist(0, 40);
    filteredMap = Map.fromEntries(entries);
  }

  await storeVal(HiveKey.lastWatchDuration, filteredMap, boxName: "animeInfo");
}

Future<void> addManualSearchQuery(String anilistId, String searchTerm) async {
  Map<dynamic, dynamic> map = await getVal(HiveKey.manualSearches, boxName: "animeInfo") ?? {};
  // if (map == null) map = {};

  map[anilistId] = searchTerm;

  Map<dynamic, dynamic> filteredMap = map;

  if (map.length > 40) {
    List<MapEntry<dynamic, dynamic>> entries = map.entries.toList();
    entries = entries.sublist(0, 40);
    filteredMap = Map.fromEntries(entries);
  }

  await storeVal(HiveKey.manualSearches, filteredMap, boxName: "animeInfo");
}
