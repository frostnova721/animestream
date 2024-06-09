class RecentlyUpdatedResult {
  final int episode;
  final Map<String, String?> title;
  final int id;
  final String type;
  final String? banner;
  final String cover;
  final dynamic genres;
  final String releaseStatus;
  final int? rating;

  RecentlyUpdatedResult({
    required this.episode,
    required this.title,
    required this.id,
    required this.type,
    required this.banner,
    required this.cover,
    required this.genres,
    required this.releaseStatus,
    this.rating = null,
  });
}

class TrendingResult {
  final int id;
  final Map<String, String?> title;
  final List<Object?> genres;
  final int? rating;
  final String cover;
  final String? banner;

  TrendingResult({
    required this.id,
    required this.banner,
    required this.cover,
    required this.genres,
    required this.rating,
    required this.title,
  });
}

class UserModal {
  final int id;
  final String? banner;
  final String? avatar;
  final String name;

  UserModal({
    required this.avatar,
    required this.banner,
    required this.id,
    required this.name,
  });
}

class UserAnimeList {
  final String name;
  final String status;
  final List<UserAnimeListItem> list;

  UserAnimeList({
    required this.list,
    required this.name,
    required this.status,
  });
}

class UserAnimeListItem {
  final int id;
  final Map<String, String?> title;
  // final String releaseStatus;
  final String coverImage;
  final int? watchProgress;
  final double? rating;

  UserAnimeListItem({
    required this.id,
    required this.title,
    // required this.releaseStatus,
    required this.coverImage,
    required this.watchProgress,
    required this.rating,
  });
}

class AnilistInfo {
  final Map<String, String?> title;
  final Map<String, String> aired;
  final String? banner;
  final String cover;
  final String duration;
  final int? episodes;
  final List<dynamic> genres;
  final List<Map<String, dynamic>> characters;
  final Object nextAiringEpisode;
  final double? rating;
  final List<dynamic> recommended;
  final List<dynamic> related;
  final String? status;
  final String type;
  final List<String?> studios;
  final List<Object?> synonyms;
  final String? synopsis;
  final List<String> tags;
  final String? mediaListStatus;

  AnilistInfo({
    required this.aired,
    required this.banner,
    required this.characters,
    required this.cover,
    required this.duration,
    required this.episodes,
    required this.genres,
    required this.mediaListStatus,
    required this.nextAiringEpisode,
    required this.rating,
    required this.recommended,
    required this.related,
    required this.status,
    required this.studios,
    required this.synonyms,
    required this.synopsis,
    required this.tags,
    required this.title,
    required this.type,
  });
}

class AnilistMutationResult {
  final String status;
  final int? progress;

  AnilistMutationResult({required this.status, required this.progress});
}

class AnilistRecommendations {
  final int id;
  final Map<String, String?> title;
  final String cover;
  
  AnilistRecommendations({required this.cover, required this.id, required this.title});
}

class CurrentlyAiringResult {
  final int id;
  final Map<String, String?> title;
  final String cover;
  final String status;
  final double? rating;

  CurrentlyAiringResult({required this.cover, required this.id, required this.status, required this.title, required this.rating});
}

class AnilistSearchResult {
  final int id;
  final int? idMal;
  final Map<String, String?> title;
  final String cover;

  AnilistSearchResult({required this.cover, required this.id, required this.idMal, required this.title});
}

class AnimeCardData {
  final int id;
  final Map<String, String?> title;
  final String cover;
  final String status;

  AnimeCardData({required this.cover, required this.id, required this.status, required this.title});
}

class GenreWatchStats {
  final int count;
  final int minutesWatched;
  final String genre; 

  GenreWatchStats({required this.count, required this.genre, required this.minutesWatched});
}


class AnilistUserStats {
  /**the items not in planned but from every other list */
  final int notInPlanned;
  final int minutesWatched;
  final int episodesWatched;
  final List<GenreWatchStats> genres;

  AnilistUserStats({required this.episodesWatched, required this.genres, required this.minutesWatched, required this.notInPlanned});
}

