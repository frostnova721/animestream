import 'package:animestream/core/commons/utils.dart';
import 'package:animestream/core/data/hive.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:graphql/client.dart';

class Anilist {
  Future<List<AnilistSearchResult>> search(String query) async {
    final gquery = '''
            query {
                Page(perPage: 10) {
                    media(search: "$query", type: ANIME, isAdult: false) {
                        id
                        idMal
                        title {
                            english
                            romaji
                        }
                        coverImage {
                            large
                        }
                    }
                }
            }
        ''';
    final data = await fetchQuery(gquery, RequestType.media);

    List<AnilistSearchResult> searchResults = [];

    if (data.length == 0) {
      return [];
    }

    data.forEach((item) {
      final classified =
          AnilistSearchResult(cover: item['coverImage']['large'], id: item['id'], idMal: item['idMal'], title: {
        'english': item['title']['english'],
        'romaji': item['title']['romaji'],
      });
      searchResults.add(classified);
    });

    return searchResults;
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

    final List<dynamic> data = await fetchQuery(query, RequestType.media, token: await getVal('token'));

    final List<CurrentlyAiringResult> airingAnimes = [];

    for (final airingAnime in data) {
      airingAnimes.add(
        CurrentlyAiringResult(
          cover: airingAnime['coverImage']['large'],
          id: airingAnime['id'],
          status: airingAnime['status'],
          rating: (airingAnime['averageScore'] ?? 0) / 10,
          title: {'english': airingAnime['title']['english'], 'romaji': airingAnime['title']['romaji']},
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
    try {
      final res = await fetchQuery(query, RequestType.recentlyUpdatedAnime);
      final List<dynamic> recentlyUpdatedAnimes = res;

      final List<RecentlyUpdatedResult> trendingList = [];

      for (final recentlyUpdatedAnime in recentlyUpdatedAnimes) {
        if (recentlyUpdatedAnime['media']['isAdult'] == true ||
            recentlyUpdatedAnime['media']['countryOfOrigin'] != "JP") continue;
        final RecentlyUpdatedResult data = RecentlyUpdatedResult(
          episode: recentlyUpdatedAnime['episode'],
          title: {
            'english': recentlyUpdatedAnime['media']['title']['english'],
            'romaji': recentlyUpdatedAnime['media']['title']['romaji']
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
    } catch (err) {
      print(err);
      throw new Exception("ERR_COULDNT_GET_TRENDING_LIST");
    }
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
    final List<dynamic> trendings = await fetchQuery(gquery, RequestType.media);

    final List<TrendingResult> typed = [];

    for (final trending in trendings) {
      final TrendingResult data = TrendingResult(
        id: trending['id'],
        banner: trending['bannerImage'],
        cover: trending['coverImage']['large'],
        genres: trending['genres'],
        rating: trending['averageScore'],
        title: {'english': trending['title']['english'], 'romaji': trending['title']['romaji']},
      );
      typed.add(data);
    }

    return typed;
  }

  fetchQuery(String query, RequestType? type, {String? token}) async {
    GraphQLClient client;
    if (token != null)
      client = GraphQLClient(
        link: HttpLink("https://graphql.anilist.co", defaultHeaders: {'Authorization': 'Bearer $token'}),
        cache: GraphQLCache(),
      );
    else
      client = GraphQLClient(
        link: HttpLink("https://graphql.anilist.co"),
        cache: GraphQLCache(),
      );

    QueryResult res;

    if (type == RequestType.mutate) {
      final MutationOptions options = MutationOptions(
        document: gql(query),
      );
      res = await client.mutate(options);
      return res.data;
    } else {
      final QueryOptions options = QueryOptions(
        document: gql(query),
      );
      res = await client.query(options);
    }
    if (res.hasException) {
      print(res.exception.toString());
    }

    if (type == null) return res.data;

    if (type == RequestType.media) {
      final data = res.data?['Page']['media'];

      return data;
    }
    if (type == RequestType.recentlyUpdatedAnime) {
      final data = res.data?['Page']['airingSchedules'];

      return data;
    }
  }
}
