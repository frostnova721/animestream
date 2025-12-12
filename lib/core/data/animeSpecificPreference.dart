import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums/hiveEnums.dart';
import 'package:animestream/core/data/hive.dart';
import 'package:animestream/core/data/types.dart';
import 'package:animestream/core/database/database.dart';
import 'package:hive/hive.dart';

/// Max number of anime-specific preference entries to retain (LRU policy)
const int _animeInfoLruCapacity = 40;

final String _boxName = HiveBox.animeInfo.boxName;

/// Retruns an object of [AnimeSpecificPreference] if it exists!
Future<AnimeSpecificPreference?> getAnimeSpecificPreference(String anilistId) async {
  //just handle anilist
  if (currentUserSettings?.database != Databases.anilist) return null;

  var box = await Hive.openBox(_boxName);
  if (!box.isOpen) {
    box = await Hive.openBox(_boxName);
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

  // Update lastAccessed for LRU on read
  if (item.isNotEmpty) {
    item['lastAccessed'] = DateTime.now().millisecondsSinceEpoch;
    asp[anilistId] = item;
    await box.put(HiveKey.animeSpecificPreference.name, asp);
  }

  await box.close();

  return AnimeSpecificPreference(
      lastWatchDuration: lastWatch, manualSearchQuery: manSearch, preferredProvider: provider);
}

Future<void> saveAnimeSpecificPreference(String anilistId, AnimeSpecificPreference preference) async {
  Map<dynamic, dynamic> map = Map.castFrom(await getVal(HiveKey.animeSpecificPreference, boxName: HiveBox.animeInfo) ?? {});

  // print(map);

  final item = map[anilistId] ?? {};

  // Merge fields, with special handling for nested lastWatchDuration map
  final prefMap = preference.toMap();
  // Handle lastWatchDuration by merging existing entries instead of overwriting
  if (prefMap['lastWatchDuration'] != null) {
    final Map<dynamic, dynamic> existing = Map<dynamic, dynamic>.from(item['lastWatchDuration'] ?? {});
    final Map<dynamic, dynamic> incoming = Map<dynamic, dynamic>.from(prefMap['lastWatchDuration'] as Map);
    existing.addAll(incoming);
    item['lastWatchDuration'] = existing;
  }

  // Handle other simple fields
  for (final entry in prefMap.entries) {
    if (entry.key == 'lastWatchDuration') continue; // already merged above
    if (entry.value != null) {
      item[entry.key] = entry.value;
    }
  }

  // Update lastAccessed for LRU on write
  item['lastAccessed'] = DateTime.now().millisecondsSinceEpoch;

  map[anilistId] = item;

  // Apply LRU eviction: keep the most recently accessed _animeInfoLruCapacity entries
  Map<dynamic, dynamic> finalMap = map;
  if (map.length > _animeInfoLruCapacity) {
    final List<MapEntry<dynamic, dynamic>> entries = map.entries.toList();
    // Sort by lastAccessed descending (most recent first)
    entries.sort((a, b) {
      final aTs = (a.value is Map && (a.value)['lastAccessed'] is num) ? (a.value)['lastAccessed'] as num : 0;
      final bTs = (b.value is Map && (b.value)['lastAccessed'] is num) ? (b.value)['lastAccessed'] as num : 0;
      return bTs.compareTo(aTs);
    });
    finalMap = Map<dynamic, dynamic>.fromEntries(entries.take(_animeInfoLruCapacity));
  }

  await storeVal(HiveKey.animeSpecificPreference, finalMap, boxName: HiveBox.animeInfo);
}