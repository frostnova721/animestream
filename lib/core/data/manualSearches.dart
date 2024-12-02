import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/data/hive.dart';
import 'package:animestream/core/database/database.dart';

Future<String?> getManualSearchQuery(String anilistId) async {
  //just handle anilist
  if (currentUserSettings?.database != Databases.anilist) return null;

  final Map<dynamic, dynamic> manualSearchQuery = await getVal(HiveKey.manualSearches, boxName: "animeInfo") ?? {};
  if (manualSearchQuery.isEmpty) {
    print("EMPTY MAP 'manualSearches'");
    return null;
  }
  final item = manualSearchQuery[anilistId] ?? '';
  if (item.isEmpty) {
    print("NO QUERY FOR ALTERNATE SEARCHING");
    return null;
  }

  return item;
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
