import 'package:animestream/core/database/database.dart';
import 'package:animestream/core/database/simkl/simkl.dart';
import 'package:animestream/core/database/types.dart';

class SimklException implements Exception {
  final String message;
  final int statusCode;
  SimklException(this.message, this.statusCode);

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() {
    return "SimklException: (Message: $message, StatusCode: $statusCode)";
  }
}

class SimklSearchResult extends DatabaseSearchResult {
  final int id;
  final String cover;
  final Map<String, String?> title;
  final int? totalEpisodes;

  SimklSearchResult({
    required this.cover,
    required this.id,
    required this.title,
    this.totalEpisodes = null,
  });
}

class SimklRelatedRecommendation extends DatabaseRelatedRecommendation {
  final int id;
  final Map<String, String?> title;
  final String cover;
  final String type;
  final double? rating;
  final String? relationType;

  SimklRelatedRecommendation({
    required this.id,
    required this.title,
    required this.cover,
    required this.type,
    required this.relationType,
    this.rating,
  });

  factory SimklRelatedRecommendation.fromJson(Map<String, dynamic> json) {
    return SimklRelatedRecommendation(
      id: json['ids']['simkl'],
      title: {
        'romaji': json['title'],
        'english': json['en_title'] as String?,
      },
      cover: Simkl.imageLink(json['poster'] ?? ""), // not really a good idea. But yeah!
      type: json['anime_type'],
      rating: json['ratings']?['simkl']?['rating']?.toDouble(),
      relationType: json['relation_type'] ?? null,
    );
  }
}

class SimklInfo extends DatabaseInfo {
  final Map<String, String?> title;
  final Map<String, String?> aired;
  final String type;
  final String duration;
  final String cover;
  final double rating;
  final List<dynamic> genres;
  final List<SimklRelatedRecommendation> recommended;
  //fanart
  final String? banner;
  final String? status;
  final String? synopsis;
  final List<String?> studios;
  final List<Object?> synonyms;
  final List<SimklRelatedRecommendation> related;
  //really hope they add it
  final List<Map<String, dynamic>> characters;
  final int? episodes;
  final List<AlternateDatabaseId> alternateDatabases;

  SimklInfo({
    required this.title,
    required this.aired,
    required this.type,
    required this.duration,
    required this.cover,
    required this.rating,
    required this.genres,
    required this.recommended,
    required this.banner,
    required this.status,
    required this.synopsis,
    required this.studios,
    required this.synonyms,
    required this.related,
    required this.characters,
    required this.episodes,
    required this.alternateDatabases,
  });

  factory SimklInfo.fromJson(Map<String, dynamic> json) {
    String? getTitleFromAltTitles(int langCode) {
      final titleList = (json['alt_titles'] as List?)?.where((it) => it['lang'] == langCode).toList();
      if (titleList == null || titleList.isEmpty) return null;
      return titleList[0]['name'];
    }

    return SimklInfo(
        title: {
          'romaji': getTitleFromAltTitles(33) ?? json['title'],
          'english': getTitleFromAltTitles(7) ?? json['en_title'],
        },
        aired: {
          'start': json['first_aired'],
          'end': json['last_aired'],
        },
        type: json['anime_type'],
        duration: "${json['runtime']} min",
        cover: Simkl.imageLink(json['poster']),
        rating: json['ratings']?['simkl']['rating']?.toDouble() ?? 0,
        genres: List<String>.from(json['genres']),
        recommended:
            (json['users_recommendations'] as List?)?.map((rec) => SimklRelatedRecommendation.fromJson(rec)).toList() ??
                [],
        banner: json['fanart'] != null ? Simkl.imageLink(json['fanart'], fanart: true) : null,
        status: json['status'],
        synopsis: json['overview'],
        studios: (json['studios'] as List).map((studio) => studio['name'] as String?).toList(),
        synonyms: json['alt_titles'].map<String?>((alt) => alt['name'] as String?).toList(),
        related: (json['relations'] as List?)?.map((rel) => SimklRelatedRecommendation.fromJson(rel)).toList() ?? [],
        characters: [], // Placeholder for now, as characters aren't provided
        episodes: json['total_episodes'],
        alternateDatabases: [
          if (json['ids']['anilist'] != null)
            AlternateDatabaseId(database: Databases.anilist, id: int.parse(json['ids']['anilist'])),
          AlternateDatabaseId(database: Databases.simkl, id: json['ids']['simkl']),
          if (json['ids']['mal'] != null)
            AlternateDatabaseId(database: Databases.mal, id: int.parse(json['ids']['mal'])),
        ]);
  }
}

//idk just leave this mf here
class SimklMutationResult extends DatabaseMutationResult {}


class SimklAnimeWatchProgress extends DatabaseAnimeWatchProgress {
  final int id;
  final int? progress;
  final int? totalEpisodes;
  final String? status;

  SimklAnimeWatchProgress({
    required this.id,
    required this.progress,
    required this.totalEpisodes,
    required this.status,
  });

  factory SimklAnimeWatchProgress.fromJson(int animeId, dynamic data) {
    Map<String, dynamic>? item;

    if (data is List && data.isNotEmpty) {
      final match = data.firstWhere(
        (it) =>
            it is Map &&
            (it['ids']?['simkl'] == animeId || it['anime']?['ids']?['simkl'] == animeId),
        orElse: () => data.first,
      );
      if (match is Map<String, dynamic>) {
        item = match;
      }
    } else if (data is Map<String, dynamic>) {
      if (data['anime'] is List && (data['anime'] as List).isNotEmpty) {
        final first = (data['anime'] as List).first;
        if (first is Map<String, dynamic>) item = first;
      } else if (data['shows'] is List && (data['shows'] as List).isNotEmpty) {
        final first = (data['shows'] as List).first;
        if (first is Map<String, dynamic>) item = first;
      } else if (data.containsKey('list') ||
          data.containsKey('status') ||
          data.containsKey('episodes_watched')) {
        item = data;
      }
    }

    int? parseInt(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      return int.tryParse(val.toString());
    }

    int? progress;
    int? totalEpisodes;
    String? status;

    if (item != null) {
      progress = parseInt(item['episodes_watched'] ??
          item['episodes_watched_count'] ??
          item['watched_episodes_count']);
      totalEpisodes = parseInt(item['episodes_total'] ??
          item['total_episodes_count'] ??
          item['total_episodes'] ??
          item['anime']?['episodes_total'] ??
          item['anime']?['total_episodes'] ??
          item['show']?['episodes_total']);
      status = (item['list'] ?? item['status'])?.toString();
    }

    return SimklAnimeWatchProgress(
      id: animeId,
      progress: progress,
      totalEpisodes: totalEpisodes,
      status: status,
    );
  }
}
