import 'package:animestream/core/database/database.dart';

abstract class DatabaseSearchResult {
  int get id;
  Map<String, String?> get title;
  String get cover;
  double? rating;
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
}

abstract class DatabaseMutationResult {
  String? status;
  int? progress;
}

abstract class DatabaseInfo {
  Map<String, String?> get title;
  Map<String, String> get aired;
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
  List<AlternateDatabaseId> get alternateDatabases;
}
