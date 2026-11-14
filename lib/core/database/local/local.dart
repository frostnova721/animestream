import 'package:hive/hive.dart';

import 'package:animestream/core/app/logging.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/commons/enums/hiveEnums.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/core/database/database.dart';
import 'package:animestream/core/database/local/types.dart';
import 'package:animestream/core/database/types.dart';

class LocalTracker implements Tracker {
  LocalTracker({Databases? source}) : source = source ?? currentUserSettings?.database ?? Databases.anilist;

  /// The database the ids passed to / returned from this instance belong to.
  final Databases source;

  static Future<Box>? _boxFuture;

  static final Map<String, String> _aliases = {};

  static Future<Box> _open() {
    return _boxFuture ??= _init().catchError((Object e) {
      _boxFuture = null; // allow a retry on the next call
      throw e;
    });
  }

  static Future<Box> _init() async {
    final box = await Hive.openBox(HiveBox.localTracker.boxName);
    await _migrateLegacy(box);

    _aliases.clear();
    for (final key in box.keys) {
      final raw = box.get(key);
      if (key is! String || raw is! Map) continue;
      for (final alias in _aliasesOf(LocalEntry.fromMap(raw))) {
        _aliases[alias] = key;
      }
    }
    return box;
  }

  static String _alias(Databases db, int id) => '${db.name}:$id';

  static Iterable<String> _aliasesOf(LocalEntry entry) => entry.ids.entries.map((e) => _alias(e.key, e.value));

  static const Map<MediaStatus, String> _listNames = {
    MediaStatus.CURRENT: "Watching",
    MediaStatus.PLANNING: "Planning",
    MediaStatus.COMPLETED: "Completed",
    MediaStatus.PAUSED: "Paused",
    MediaStatus.DROPPED: "Dropped",
  };

  /// All ids for this call: [id] in [source], plus [otherIds].
  Map<Databases, int> _idsFor(int id, List<AlternateDatabaseId>? otherIds) => {
        for (final o in otherIds ?? const <AlternateDatabaseId>[]) o.database: o.id,
        source: id,
      };

  /// Finds the entry for these ids, or creates a new one (not yet saved).
  ///
  /// If the ids point at more than one entry (same anime tracked separately before the ids
  /// got linked), they're merged into the most recently updated one and the rest are deleted.
  Future<(String, LocalEntry)> _resolve(Box box, Map<Databases, int> ids) async {
    final Map<String, LocalEntry> found = {};
    for (final e in ids.entries) {
      final key = _aliases[_alias(e.key, e.value)];
      if (key == null || found.containsKey(key)) continue;
      final raw = box.get(key);
      if (raw is Map) found[key] = LocalEntry.fromMap(raw);
    }

    if (found.isEmpty) {
      return (_alias(source, ids[source]!), LocalEntry(ids: {...ids}, title: const {}, cover: ''));
    }

    // newest first; on a tie prefer the entry of the database the user is acting on
    final sourceKey = _aliases[_alias(source, ids[source]!)];
    final sorted = found.entries.toList()
      ..sort((a, b) {
        final byTime = b.value.updatedAt.compareTo(a.value.updatedAt);
        if (byTime != 0) return byTime;
        return (b.key == sourceKey ? 1 : 0) - (a.key == sourceKey ? 1 : 0);
      });
    final (key, entry) = (sorted.first.key, sorted.first.value);

    for (final other in sorted.skip(1)) {
      final o = other.value;
      entry.ids.addAll({...o.ids}..addAll(entry.ids)); // keep the newer entry's ids on conflict
      if (entry.title.isEmpty) entry.title = o.title;
      if (entry.cover.isEmpty) entry.cover = o.cover;
      entry.totalEpisodes ??= o.totalEpisodes;
      entry.rating ??= o.rating;
      entry.status ??= o.status;
      await box.delete(other.key);
      _aliases.removeWhere((_, v) => v == other.key);
    }

    entry.ids.addAll(ids);
    return (key, entry);
  }

  Future<void> _save(Box box, String key, LocalEntry entry) async {
    await box.put(key, entry.toMap());
    _aliases.removeWhere((_, v) => v == key); // drop aliases of ids that changed
    for (final alias in _aliasesOf(entry)) {
      _aliases[alias] = key;
    }
  }

  /// Returns the entry for [id] (in [source]), or null if it doesn't exist.
  Future<LocalEntry?> getEntry(int id) async {
    final box = await _open();
    final key = _aliases[_alias(source, id)];
    final raw = key == null ? null : box.get(key);
    return raw is Map ? LocalEntry.fromMap(raw) : null;
  }

  /// Stores/refreshes display info for an anime. Remote trackers already know this,
  /// the local one needs it to show the entry in lists.
  ///
  /// Doesn't add the anime to any list on its own, use [mutateAnimeList] for that.
  Future<void> saveMeta({
    required int id,
    required Map<String, String?> title,
    required String cover,
    int? totalEpisodes,
    double? rating,
    List<AlternateDatabaseId>? otherIds,
  }) async {
    final box = await _open();
    final (key, entry) = await _resolve(box, _idsFor(id, otherIds));
    entry
      ..title = title
      ..cover = cover
      ..totalEpisodes = totalEpisodes ?? entry.totalEpisodes
      ..rating = rating ?? entry.rating;
    await _save(box, key, entry);
  }

  @override
  Future<DatabaseAnimeWatchProgress> getAnimeWatchProgress(int id) async {
    final entry = await getEntry(id);
    final inList = entry?.status != null;
    return LocalWatchProgress(
      id: id,
      progress: inList ? entry!.progress : null,
      status: entry?.status?.name,
      totalEpisodes: entry?.totalEpisodes,
    );
  }

  /// [userName] is ignored. Items in each list are ordered oldest update first,
  /// same as AniList's response (callers reverse it).
  ///
  /// Entries with no id for [source] yet (never opened while that database was active)
  /// are left out, since the UI couldn't open them.
  @override
  Future<List<UserAnimeList>> getUserAnimeList(String userName, {List<MediaStatus>? status}) async {
    final box = await _open();
    final wanted = (status == null || status.isEmpty) ? MediaStatus.values.toSet() : status.toSet();

    final Map<MediaStatus, List<LocalEntry>> grouped = {};
    for (final raw in box.values) {
      if (raw is! Map) continue;
      final entry = LocalEntry.fromMap(raw);
      final entryStatus = entry.status;
      if (entryStatus == null || !wanted.contains(entryStatus) || !entry.ids.containsKey(source)) continue;
      (grouped[entryStatus] ??= []).add(entry);
    }

    return [
      for (final s in MediaStatus.values)
        if (grouped[s] case final entries?)
          UserAnimeList(
            name: _listNames[s]!,
            status: s.name,
            list: (entries..sort((a, b) => a.updatedAt.compareTo(b.updatedAt)))
                .map((e) => e.toListItem(e.ids[source]!))
                .toList(),
          ),
    ];
  }

  /// Null [status]/[progress] keep the existing values. A new entry defaults to CURRENT.
  /// A CURRENT entry whose progress reaches the total episode count becomes COMPLETED.
  @override
  Future<DatabaseMutationResult?> mutateAnimeList({
    required int id,
    MediaStatus? status,
    int? progress,
    MediaStatus? previousStatus, // not needed locally
    List<AlternateDatabaseId>? otherIds,
  }) async {
    final box = await _open();
    final (key, entry) = await _resolve(box, _idsFor(id, otherIds));

    if (progress != null) entry.progress = progress;
    entry.status = status ?? entry.status ?? MediaStatus.CURRENT;

    final total = entry.totalEpisodes;
    if (entry.status == MediaStatus.CURRENT && total != null && total > 0 && entry.progress >= total) {
      entry.status = MediaStatus.COMPLETED;
    }

    entry.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await _save(box, key, entry);

    return LocalMutationResult(status: entry.status!.name, progress: entry.progress);
  }

  @override
  Future<DatabaseMutationResult?> deleteAnimeEntry({required int id}) async {
    final box = await _open();
    final key = _aliases[_alias(source, id)];
    if (key == null) return null;
    await box.delete(key);
    _aliases.removeWhere((_, v) => v == key);
    return null;
  }

  /// One-time move of the old `watching` list (animestream box) into this box.
  /// Old entries were CURRENT-only, had a plain string title and only the active database's id.
  static Future<void> _migrateLegacy(Box box) async {
    try {
      final legacyBox = await Hive.openBox(HiveBox.animestream.boxName);
      final legacy = legacyBox.get(HiveKey.watching.name);
      if (legacy is! List || legacy.isEmpty) return;

      final db = currentUserSettings?.database ?? Databases.anilist;
      final now = DateTime.now().millisecondsSinceEpoch;
      final Map<String, dynamic> migrated = {};

      for (final (i, raw) in legacy.indexed) {
        if (raw is! Map || raw['id'] is! int) continue;
        final id = raw['id'] as int;
        final key = _alias(db, id);
        if (box.containsKey(key)) continue;

        final title = raw['title'] as String? ?? '';
        migrated[key] = LocalEntry(
          ids: {db: id},
          title: {'english': title, 'romaji': title},
          cover: raw['imageUrl'] as String? ?? '',
          totalEpisodes: raw['totalEpisodes'] as int?,
          rating: (raw['rating'] as num?)?.toDouble(),
          status: MediaStatus.CURRENT,
          progress: raw['watched'] as int? ?? 0,
          // legacy list is oldest-first; keep that order
          updatedAt: now - (legacy.length - i),
        ).toMap();
      }

      await box.putAll(migrated);
      await legacyBox.delete(HiveKey.watching.name);
      Logs.app.log("[LOCAL TRACKER] Migrated ${migrated.length} legacy entries");
    } catch (err) {
      // non-fatal, the legacy data stays where it was and we retry next launch
      Logs.app.log("[LOCAL TRACKER] Legacy migration failed: $err");
    }
  }
}
