import 'package:animestream/core/app/logging.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums/hiveEnums.dart';
import 'package:animestream/core/data/models/animeSpecificPreference.dart';
import 'package:animestream/core/database/database.dart';
import 'package:hive/hive.dart';

/// Max number of anime-specific preference entries to retain (LRU policy)
const int _animeInfoLruCapacity = 40;

final String _boxName = HiveBox.animeInfo.boxName;

// final _cache = <String, AnimeSpecificPreference?>{};

// The box is kept open: Hive.openBox hands out the same instance to every caller, so closing it
// after each access broke overlapping calls ("Box has already been closed"), e.g. the player's
// save on exit racing the info page's getWatched(). Only this file uses the animeInfo box.
Box? _box;

Future<Box> _open() async {
  final box = _box;
  if (box != null && box.isOpen) return box;
  return _box = await Hive.openBox(_boxName);
}

Future<void> _queue = Future.value();

/// Runs [fn] once the previous read/write is done. Both functions here do a read-modify-write
/// of the same map, so overlapping calls would lose updates, and a read could miss a save
/// that started just before it (player exit -> info page refresh).
Future<T> _serialized<T>(Future<T> Function() fn) {
  final result = _queue.then((_) => fn());
  _queue = result.then((_) {}, onError: (_) {});
  return result;
}

/// Retruns an object of [AnimeSpecificPreference] if it exists!
Future<AnimeSpecificPreference?> getAnimeSpecificPreference(String anilistId) async {
  //just handle anilist
  if (currentUserSettings?.database != Databases.anilist) return null;

  return _serialized(() => _getAnimeSpecificPreference(anilistId));
}

Future<AnimeSpecificPreference?> _getAnimeSpecificPreference(String anilistId) async {
  final box = await _open();

  String? manSearch, provider;
  Map<dynamic, dynamic>? lastWatch;

  final Map<dynamic, dynamic> asp = await box.get(HiveKey.animeSpecificPreference.name) ?? {};
  if (asp.isEmpty) {
    Logs.app.log("EMPTY MAP 'animeSpecificPreference'");
  }

  final Map<String, dynamic> item = Map.castFrom(asp[anilistId] ?? {});
  manSearch = item["manualSearchQuery"];
  lastWatch = item['lastWatchDuration'];
  provider = item['preferredProvider'];
  Logs.app.log(item.toString());

  // Update lastAccessed for LRU on read
  if (item.isNotEmpty) {
    item['lastAccessed'] = DateTime.now().millisecondsSinceEpoch;
    asp[anilistId] = item;
    await box.put(HiveKey.animeSpecificPreference.name, asp);
  }

  return AnimeSpecificPreference(
      lastWatchDuration: lastWatch,
      manualSearchQuery: manSearch,
      preferredProvider: provider,
      previouslyUsedServer: item['previouslyUsedServer']);
}

Future<void> saveAnimeSpecificPreference(String anilistId, AnimeSpecificPreference preference) {
  return _serialized(() => _saveAnimeSpecificPreference(anilistId, preference));
}

Future<void> _saveAnimeSpecificPreference(String anilistId, AnimeSpecificPreference preference) async {
  final box = await _open();
  Map<dynamic, dynamic> map = Map.castFrom(box.get(HiveKey.animeSpecificPreference.name) ?? {});

  // print(map);

  final item = map[anilistId] ?? {};

  // Merge fields, with special handling for nested lastWatchDuration map
  final prefMap = preference.toMap();
  // Handle lastWatchDuration by merging existing entries instead of overwriting
  if (prefMap['lastWatchDuration'] != null) {
    final Map<dynamic, dynamic> existing = Map<dynamic, dynamic>.from(item['lastWatchDuration'] ?? {});
    final Map<dynamic, dynamic> incoming = Map<dynamic, dynamic>.from(prefMap['lastWatchDuration'] as Map);

    if(incoming.isEmpty) {
      existing.clear();
    } else {
    existing.addAll(incoming);
    }
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

  await box.put(HiveKey.animeSpecificPreference.name, finalMap);
}
