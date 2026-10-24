import 'package:animestream/core/database/database.dart';

abstract class DatabaseSearchResult {
  int get id;
  Map<String, String?> get title;
  String get cover;
  double? rating;
  int? get totalEpisodes;
}

abstract class DatabaseRelatedRecommendation {
  int get id;
  Map<String, String?> get title;
  String get cover;
  String get type;
  double? rating;
  String? relationType;
}

class AlternateDatabaseId {
  Databases database;
  int id;

  AlternateDatabaseId({
    required this.database,
    required this.id,
  });

  @override
  bool operator ==(Object other) =>
      (other is AlternateDatabaseId &&
          database == other.database &&
          id == other.id) || identical(this, other);

  @override
  int get hashCode => Object.hash(database, id);

  @override
  String toString() {
    return 'AlternateDatabaseId{database: $database, id: $id}';
  }
}

abstract class DatabaseMutationResult {
  String? status;
  int? progress;
}

abstract class DatabaseInfo {
  Map<String, String?> get title;
  Map<String, String?> get aired;
  String? get banner;
  String get cover;
  String get duration;
  int? get episodes;
  List<dynamic> get genres;
  List<Map<String, dynamic>> get characters;
  Object? nextAiringEpisode;
  double? rating;
  List<DatabaseRelatedRecommendation> get recommended;
  List<DatabaseRelatedRecommendation> get related;
  String? get status;
  String get type;
  List<String?> get studios;
  List<Object?> get synonyms;
  String? get synopsis;
  List<String>? tags;
  String? mediaListStatus;
  int? progress;
  int? userScore;
  List<AlternateDatabaseId> get alternateDatabases;
  int? listId;
}

abstract class DatabaseAnimeWatchProgress {
  int get id;
  int? get progress;
  String? get status;

  // Total episodes can be null, for some animes like one piece
  int? get totalEpisodes;
}

// abstract class DatabaseUserAnimeList {
//   /// Status of the list, e.g. "CURRENT", "COMPLETED", etc.
//   String get status;

//   /// List's name
//   String get name;

//   /// List's items, which are of type [DatabaseUserAnimeListItem]
//   List<DatabaseUserAnimeListItem> get animeList;
// }

// abstract class DatabaseUserAnimeListItem {
//   int get id;
//   Map<String, String?> get title;
//   String get cover;
//   double? get rating;
//   int? get progress;
//   int? get totalEpisodes;
//   // String? get status;
// }