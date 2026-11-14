import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/core/database/database.dart';
import 'package:animestream/core/database/types.dart';

/// A single anime in the local tracker.
///
/// One entry per anime, holding every database id it's known by ([ids]),
/// so switching the active database (AniList <-> Simkl) keeps the library intact.
///
/// [status] is null for "meta only" entries (saved via saveMeta but never added to a list).
/// Those are not shown in any list.
class LocalEntry {
  final Map<Databases, int> ids;
  Map<String, String?> title;
  String cover;
  int? totalEpisodes;
  double? rating;
  MediaStatus? status;
  int progress;
  int updatedAt;

  LocalEntry({
    required this.ids,
    required this.title,
    required this.cover,
    this.totalEpisodes,
    this.rating,
    this.status,
    this.progress = 0,
    this.updatedAt = 0,
  });

  Map<String, dynamic> toMap() => {
        'ids': {for (final e in ids.entries) e.key.name: e.value},
        'title': title,
        'cover': cover,
        'totalEpisodes': totalEpisodes,
        'rating': rating,
        'status': status?.name,
        'progress': progress,
        'updatedAt': updatedAt,
      };

  factory LocalEntry.fromMap(Map<dynamic, dynamic> map) {
    final dbs = Databases.values.asNameMap();
    return LocalEntry(
      ids: {
        for (final e in (map['ids'] as Map? ?? const {}).entries)
          if (dbs[e.key] case final db?) db: e.value as int,
      },
      title: Map<String, String?>.from(map['title'] as Map? ?? const {}),
      cover: map['cover'] as String? ?? '',
      totalEpisodes: map['totalEpisodes'] as int?,
      rating: (map['rating'] as num?)?.toDouble(),
      status: MediaStatus.values.asNameMap()[map['status']],
      progress: map['progress'] as int? ?? 0,
      updatedAt: map['updatedAt'] as int? ?? 0,
    );
  }

  /// [id] is the anime's id in the database the caller is using.
  UserAnimeListItem toListItem(int id) => UserAnimeListItem(
        id: id,
        title: title,
        coverImage: cover,
        watchProgress: progress,
        rating: rating,
        episodes: totalEpisodes,
      );
}

class LocalWatchProgress extends DatabaseAnimeWatchProgress {
  @override
  final int id;
  @override
  final int? progress;
  @override
  final String? status;
  @override
  final int? totalEpisodes;

  LocalWatchProgress({required this.id, required this.progress, required this.status, required this.totalEpisodes});
}

class LocalMutationResult extends DatabaseMutationResult {
  LocalMutationResult({required String status, required int progress}) {
    this.status = status;
    this.progress = progress;
  }
}

class LocalMeta {
  final Map<String, String?> title;
  final String cover;
  final int? totalEpisodes;
  final double? rating;
  const LocalMeta({required this.title, required this.cover, this.totalEpisodes, this.rating});
}

