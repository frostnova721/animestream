import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/data/hive.dart';
import 'package:animestream/core/data/types.dart';
import 'package:animestream/core/database/database.dart';

/// Retruns the duration on last watched episode in seconds
Future<AnimeSpecificPreference?> getAnimeSpecificPreference(String anilistId) async {
  //just handle anilist
  if (currentUserSettings?.database != Databases.anilist) return null;

  final Map<dynamic, dynamic> lastWatch = await getVal(HiveKey.lastWatchDuration, boxName: "animeInfo") ?? {};
  if (lastWatch.isEmpty) {
    print("EMPTY MAP 'lastWatchDuration'");
    return null;
  }
  final Map<dynamic, dynamic>? lastWatchDuration = lastWatch[anilistId] ?? null;

  final Map<dynamic, dynamic> manualSearchQuery = await getVal(HiveKey.manualSearches, boxName: "animeInfo") ?? {};
  if (manualSearchQuery.isEmpty) {
    print("EMPTY MAP 'manualSearches'");
    return null;
  }
  final manualSearchString = manualSearchQuery[anilistId] ?? '';
  if (manualSearchString.isEmpty) {
    print("NO QUERY FOR ALTERNATE SEARCHING");
    return null;
  }

  return AnimeSpecificPreference(lastWatchDuration: lastWatchDuration, manualSearchQuery: manualSearchString);
}

Future<void> addLastWatchedDuration(String anilistId, Map<int, double> item) async {
  Map<dynamic, dynamic> map = await getVal(HiveKey.lastWatchDuration, boxName: "animeInfo") ?? {};

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
