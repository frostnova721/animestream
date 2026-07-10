import 'package:animestream/core/app/values.dart';
import 'package:animestream/core/network/network.dart';

import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/commons/utils.dart';
import 'package:animestream/core/data/secureStorage.dart';
import 'package:animestream/core/database/anilist/queries.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/core/database/database.dart';
import 'package:animestream/core/database/types.dart';

class AnilistApiException implements Exception {
  final String message;
  final int? statusCode;

  const AnilistApiException(this.message, {this.statusCode});

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => 'AnilistApiException(statusCode: $statusCode, message: $message)';
}

class Anilist extends Database {
  Future<List<AnilistSearchResult>> search(String query) async {
    final gquery = '''
            query {
                Page(perPage: 15) {
                    media(search: "$query", type: ANIME, isAdult: false) {
                        id
                        idMal
                        title {
                            english
                            romaji
                            native
                        }
                        episodes
                        averageScore
                        coverImage {
                            large
                        }
                    }
                }
            }
        ''';
    final data = await fetchQuery(
      gquery,
      RequestType.media,
      cacheDuration: const Duration(minutes: 1),
    );

    List<AnilistSearchResult> searchResults = [];

    if (data.length == 0) {
      return [];
    }

    data.forEach((item) {
      final classified = AnilistSearchResult(
          cover: item['coverImage']['large'],
          id: item['id'],
          idMal: item['idMal'],
          title: {
            'english': item['title']['english'],
            'romaji': item['title']['romaji'],
            'native': item['title']['native'],
          },
          totalEpisodes: item['episodes'],
          rating: item['averageScore'] is int ? item['averageScore'] / 10 : null);
      searchResults.add(classified);
    });

    return searchResults;
  }

  Future<AnilistInfo> getAnimeInfo(int id) async {
    final query = AnilistQueries.infoQuery(id);
    final String? token = await getSecureVal(SecureStorageKey.anilistToken);
    final result = await Anilist().fetchQuery(
      query,
      RequestType.media,
      token: token,
      // WARN: THIS WILL CAUSE PROBLEM WHEN IMPLEMENTING AIRING SHEDULE TIMER, SO WE CAN JUST SAVE UNIX EPOCH TIMER INSTEAD!!!
      cacheDuration: const Duration(hours: 24),
    );

    final Map<String, dynamic> info = result[0];

    AnilistInfo convertToIAnimeDetails() {
      final List<Map<String, dynamic>> characters = [];
      info['characters']['edges'].forEach((character) {
        characters.add({
          'name': character['node']['name']['full'],
          'role': character['role'],
          'image': character['node']['image']['large'] ?? character['node']['image']['medium'],
        });
      });

      final List<String> studios = [];

      info['studios']['edges'].forEach((studio) {
        if (studio['node']['isAnimationStudio'] && studio['isMain'] == true) {
          studios.add(studio['node']['name']);
        }
      });

      final List<AnilistAnimeRelatedRecommendation> recommended = [];

      info['recommendations']['nodes'].forEach((recommendation) {
        final rec = recommendation['mediaRecommendation'];
        if (rec != null) {
          recommended.add(
            AnilistAnimeRelatedRecommendation(
                id: rec['id'],
                title: {
                  'english': rec['title']['english'],
                  'romaji': rec['title']['romaji'],
                  'native': rec['title']['native'],
                },
                cover: rec['coverImage']['large'] ?? rec['coverImage']['extraLarge'],
                type: rec['type'],
                rating: rec['averageScore'] is int ? rec['averageScore'] / 10 : null),
          );
        }
      });

      final List<AnilistAnimeRelatedRecommendation> relations = [];

      info['relations']['edges'].forEach((relation) {
        relations.add(AnilistAnimeRelatedRecommendation(
            id: relation['node']['id'],
            title: {
              'english': relation['node']['title']['english'],
              'romaji': relation['node']['title']['romaji'],
              'native': relation['node']['title']['native'],
            },
            cover: relation['node']['coverImage']['large'] ?? relation['node']['coverImage']['extraLarge'],
            type: relation['node']['type'],
            rating: null,
            relationType: relation['relationType']));
      });

      List<String> tags = [];
      info['tags'].forEach((item) {
        tags.add(item['name'].toString());
      });

      final convertedGuy = AnilistInfo(
          title: {
            'english': info['title']['english'],
            'native': info['title']['native'],
            'romaji': info['title']['romaji'],
          },
          aired: {
            'start':
                '${info['startDate']['day'] ?? ''} ${MonthnumberToMonthName(info['startDate']['month'])?['short'] ?? ''} ${info['startDate']['year'] ?? ''}',
            'end':
                '${info['endDate']['day'] ?? ''} ${MonthnumberToMonthName(info['endDate']['month'])?['short'] ?? ''} ${info['endDate']['year'] ?? ''}',
          },
          banner: info['bannerImage'] ?? null,
          cover: info['coverImage']['large'] ?? info['coverImage']['medium'],
          duration: '${info['duration'] ?? ''} minutes',
          episodes: info['episodes'],
          genres: info['genres'],
          characters: characters,
          nextAiringEpisode: (
            airingAt: info['nextAiringEpisode']?['airingAt'] ?? '',
            timeLeft: info['nextAiringEpisode']?['timeUntilAiring'] ?? '',
            episode: info['nextAiringEpisode']?['episode'] ?? '',
          ),
          rating: info['averageScore'] != null ? (info['averageScore'] / 10)?.toDouble() : null,
          recommended: recommended,
          related: relations,
          status: info['status'],
          type: info['type'],
          studios: studios,
          synonyms: info['synonyms'],
          synopsis: info['description'].replaceAll(RegExp(r'<[^>]*>'), "").replaceAll(RegExp(r'\n+'), '\n'),
          tags: tags,
          mediaListStatus: info['mediaListEntry']?['status'],
          listId: info['mediaListEntry']?['id'],
          alternateDatabases: [
            AlternateDatabaseId(database: Databases.anilist, id: id),
            if (info['idMal'] != null) AlternateDatabaseId(database: Databases.mal, id: info['idMal']),
          ]);

      return convertedGuy;
    }

    return convertToIAnimeDetails();
  }

  Future<List<CurrentlyAiringResult>> getCurrentlyAiringAnime() async {
    final query = '''{
            Page(perPage: 40) {
              media(sort: [START_DATE_DESC], type: ANIME, format: TV, status: RELEASING) {
                id
                status
                title {
                  romaji
                  english
                  native
                }
                episodes
                averageScore
                coverImage {
                  large
                }
                mediaListEntry {
                  progress
                }
              }
            }
          }''';

    final List<dynamic> data = await fetchQuery(query, RequestType.media,
        token: await getSecureVal(SecureStorageKey.anilistToken), cacheDuration: const Duration(hours: 1));

    final List<CurrentlyAiringResult> airingAnimes = [];

    for (final airingAnime in data) {
      airingAnimes.add(
        CurrentlyAiringResult(
          cover: airingAnime['coverImage']['large'],
          id: airingAnime['id'],
          status: airingAnime['status'],
          rating: (airingAnime['averageScore'] ?? 0) / 10,
          title: {
            'english': airingAnime['title']['english'],
            'romaji': airingAnime['title']['romaji'],
            'native': airingAnime['title']['native'],
          },
          episodes: airingAnime['episodes'],
          watchProgress: airingAnime['mediaListEntry']?['progress'],
        ),
      );
    }

    return airingAnimes;
  }

  //maybe latest and not recentlyUpdatedAnime!
  Future<List<RecentlyUpdatedResult>> recentlyUpdated() async {
    final timeMs = (new DateTime.now().millisecondsSinceEpoch ~/ 1000) - 10000;
    final query = '''{
        Page(perPage: 25) {
    airingSchedules (airingAt_greater: 0, airingAt_lesser: $timeMs, sort: TIME_DESC) {
      episode
      media {
        title {
          english
          romaji
          native
        }
        status
        id
        type
        bannerImage
        coverImage {
          large
        }
        genres
        averageScore
        countryOfOrigin
        isAdult
      }
    }
  }
}''';
    final res = await fetchQuery(
      query,
      RequestType.recentlyUpdatedAnime,
    );
    final List<dynamic> recentlyUpdatedAnimes = res;

    final List<RecentlyUpdatedResult> trendingList = [];

    for (final recentlyUpdatedAnime in recentlyUpdatedAnimes) {
      if (recentlyUpdatedAnime['media']['isAdult'] == true || recentlyUpdatedAnime['media']['countryOfOrigin'] != "JP")
        continue;
      final RecentlyUpdatedResult data = RecentlyUpdatedResult(
        episode: recentlyUpdatedAnime['episode'],
        title: {
          'english': recentlyUpdatedAnime['media']['title']['english'],
          'romaji': recentlyUpdatedAnime['media']['title']['romaji'],
          'native': recentlyUpdatedAnime['media']['title']['native'],
        },
        id: recentlyUpdatedAnime['media']['id'],
        releaseStatus: recentlyUpdatedAnime['media']['status'],
        type: recentlyUpdatedAnime['media']['type'],
        banner: recentlyUpdatedAnime['media']['banner'],
        cover: recentlyUpdatedAnime['media']['coverImage']['large'] ?? '',
        genres: recentlyUpdatedAnime['media']['genres'],
        rating: recentlyUpdatedAnime['media']['averageScore'],
      );
      trendingList.add(data);
    }
    return trendingList;
  }

  Future<List<TrendingResult>> getTrending() async {
    final gquery = '''
            query {
                Page(perPage: 25) {
                    media(type: ANIME, sort: TRENDING_DESC, isAdult: false, season: ${getCurrentSeason()}) {
                        id
                        title {
                            english
                            romaji
                            native
                        }
                        genres
                        averageScore
                        bannerImage
                        coverImage {
                            large
                        }
                    }
                }
            }
        ''';
    final List<dynamic> trendings =
        await fetchQuery(gquery, RequestType.media, cacheDuration: const Duration(hours: 6));

    final List<TrendingResult> typed = [];

    for (final trending in trendings) {
      final TrendingResult data = TrendingResult(
        id: trending['id'],
        banner: trending['bannerImage'],
        cover: trending['coverImage']['large'],
        genres: trending['genres'],
        rating: trending['averageScore'],
        title: {
          'english': trending['title']['english'],
          'romaji': trending['title']['romaji'],
          'native': trending['title']['native'],
        },
      );
      typed.add(data);
    }

    return typed;
  }

  Future<dynamic> fetchQuery(
    String query,
    RequestType? type, {
    String? token,
    Duration? cacheDuration = Duration.zero,
  }) async {
    final headers = {
      if (token != null) 'Authorization': 'Bearer $token',
      'User-Agent': AppValues.defaultClientUserAgent,
      'Content-Type': 'application/json',
    };

    final res = await post(
      "https://graphql.anilist.co",
      headers: headers,
      body: {'query': query},
      cacheDuration: cacheDuration,
    );

    final json = res.json;
    Map<String, dynamic>? data;
    if (json is Map) {
      if (json['errors'] != null && (json['errors'] as List).isNotEmpty) {
        final errors = (json['errors'] as List)
            .map((e) => e is Map ? e['message']?.toString() ?? 'Error' : e.toString())
            .join(", ");
        throw AnilistApiException("GraphQL error: $errors", statusCode: res.statusCode);
      }
      data = json['data'] as Map<String, dynamic>?;
    } else if (json is Map<String, dynamic>) {
      data = json;
    }

    if (type == null) return data ?? json;
    if (type == RequestType.mutate) return data ?? json;
    if (type == RequestType.media) return data?['Page']?['media'];
    if (type == RequestType.recentlyUpdatedAnime) return data?['Page']?['airingSchedules'];
  }
}
