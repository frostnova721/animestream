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
   List<dynamic> get related;
   String? get status;
   String get type;
   List<String?> get studios;
   List<Object?> get synonyms;
   String? get synopsis;
   List<String>? tags;
   String? mediaListStatus;
}
