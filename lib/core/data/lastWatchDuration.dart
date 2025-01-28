import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/data/hive.dart';
import 'package:animestream/core/database/database.dart';

/// Retruns the duration on last watched episode in seconds
Future<int> getLastWatchedDuration(String anilistId) async {
  //just handle anilist
  if (currentUserSettings?.database != Databases.anilist) return 0;

  final Map<dynamic, dynamic> lastWatch = await getVal(HiveKey.lastWatchDuration, boxName: "animeInfo") ?? {};
  if (lastWatch.isEmpty) {
    print("EMPTY MAP 'lastWatchDuration'");
    return 0;
  }
  final int item = lastWatch[anilistId] ?? 0;
  // if (item.isEmpty) {
  //   print("NO QUERY FOR ALTERNATE SEARCHING");
  //   return 0;
  // }

  return item;
}


/// aah its f-cked
Future<void> addLastWatchedDuration(String anilistId, int duration) async {
  Map<dynamic, dynamic> map = await getVal(HiveKey.lastWatchDuration, boxName: "animeInfo") ?? {};
  // if (map == null) map = {};

  map[anilistId] = duration;

  Map<dynamic, dynamic> filteredMap = map;

  if (map.length > 40) {
    List<MapEntry<dynamic, dynamic>> entries = map.entries.toList();
    entries = entries.sublist(0, 40);
    filteredMap = Map.fromEntries(entries);
  }

  await storeVal(HiveKey.lastWatchDuration, filteredMap, boxName: "animeInfo");
}
