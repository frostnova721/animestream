import 'package:animestream/core/commons/utils.dart';
import 'package:animestream/core/data/hive.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:graphql/client.dart';

class Anilist {
  Future search(String query) async {
    final gquery = '''
            query {
                Page(perPage: 10) {
                    media(search: "$query", type: ANIME) {
                        id
                        idMal
                        title {
                            english
                            romaji
                        }
                        coverImage {
                            extraLarge
                            large
                        }
                    }
                }
            }
        ''';
    final data = await fetchQuery(gquery, RequestType.media);

    return data;
  }

  getCurrentlyAiringAnime() async {
    final query = '''{
            Page(perPage: 100) {
              media(sort: [START_DATE_DESC], type: ANIME, format: TV, status: RELEASING) {
                id
                title {
                  romaji
                  english
                }
                startDate {
                  year
                  month
                  day
                }
                episodes
                coverImage {
                  large
                  medium
                  color
                }
              }
            }
          }''';

    final data = await fetchQuery(query, RequestType.media);

    return data;
  }

  Future<AnilistInfo> getAnimeInfo(int anilistId) async {
    final query = '''
      {
        Page(perPage: 100) {
          media(id: $anilistId) {
            title {
              romaji
              english
              native
              userPreferred
            }
            bannerImage
            synonyms
            coverImage {
              large
              medium
            }
            genres
            description
            source
            type
            episodes
            status
            nextAiringEpisode {
              episode
              airingAt
              timeUntilAiring
            }
            tags {
              name
              category
            }
            startDate {
              year
              month
              day
            },
            endDate {
              year
              month
              day
            },
            averageScore
            studios {
              edges {
                isMain
                node {
                  isAnimationStudio
                  name
                  id
                }
              }
            }
            duration
            popularity
            characters {
              edges {
                node {
                  name {
                    full
                    native
                  }
                  image {
                    large
                    medium
                  }
                }
                role
              }
            }
            recommendations {
        nodes {
          mediaRecommendation {
            id
            type
            title {
              romaji
              english
              native
              userPreferred
            }
            coverImage {
              extraLarge
              large
            }
            
          }
        }
      }
      relations {
        edges {
          relationType
          node {
            id
            type
            title {
              romaji
              english
              native
            }
            coverImage {
              extraLarge
              large
            }
          }
        }
      }
      mediaListEntry {
        status
      }
    }
  }
}''';

    try {
      final String? token = await getVal("token");
      final result = await fetchQuery(query, RequestType.media, token: token);

      final Map<String, dynamic> info = result[0];

      AnilistInfo convertToIAnimeDetails() {
        final List<Map<String, dynamic>> characters = [];

        info['characters']['edges'].forEach((character) {
          characters.add({
            'name': character['node']['name']['full'],
            'role': character['role'],
            'image': character['node']['image']['large'] ??
                character['node']['image']['medium'],
          });
        });

        final List<String> studios = [];

        info['studios']['edges'].forEach((studio) {
          if (studio['node']['isAnimationStudio'] && studio['isMain'] == true) {
            studios.add(studio['node']['name']);
          }
        });

        final List recommended = [];

        info['recommendations']['nodes'].forEach((recommendation) {
          final rec = recommendation['mediaRecommendation'];
          if (rec != null) {
            recommended.add((
              id: rec['id'],
              title: {
                'english': rec['title']['english'],
                'romaji': rec['title']['romaji'],
                'native': rec['title']['native'],
              },
              cover:
                  rec['coverImage']['large'] ?? rec['coverImage']['extraLarge'],
              type: rec['type']
            ));
          }
        });

        final List relations = [];

        info['relations']['edges'].forEach((relation) {
          relations.add((
            id: relation['node']['id'],
            title: {
              'english': relation['node']['title']['english'],
              'romaji': relation['node']['title']['romaji'],
              'native': relation['node']['title']['native'],
            },
            cover: relation['node']['coverImage']['large'] ??
                relation['node']['coverImage']['extraLarge'],
            type: relation['node']['type'],
            relationType: relation['relationType']
          ));
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
          banner: info['bannerImage'] ?? '',
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
          rating: info['averageScore'] != null
              ? (info['averageScore'] / 10)?.toDouble()
              : null,
          recommended: recommended,
          related: relations,
          status: info['status'],
          type: info['type'],
          studios: studios,
          synonyms: info['synonyms'],
          synopsis: info['description']
              .replaceAll(RegExp(r'<[^>]*>'), "")
              .replaceAll(RegExp(r'\n+'), '\n'),
          tags: info['tags'].map((tag) => tag['name']),
          mediaListStatus: info['mediaListEntry']?['status'],
        );

        return convertedGuy;
      }

      return convertToIAnimeDetails();
    } catch (err) {
      print(err);
      throw Exception('Error Getting Anime Details');
    }
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
                Page(perPage: 10) {
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
        title: {
          'english': trending['title']['english'],
          'romaji': trending['title']['romaji']
        },
      );
      typed.add(data);
    }

    return typed;
  }

  MonthnumberToMonthName(
    dynamic monthNumber,
  ) {
    if (monthNumber == null) return {'short': '', 'full': ''};
    if (monthNumber > 12 || monthNumber < 1) return null;
    const monthName = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return {
      'full': monthName[monthNumber - 1],
      'short': monthName[monthNumber - 1].substring(0, 3),
    };
  }

  fetchQuery(String query, RequestType? type, {String? token}) async {
    GraphQLClient client;
    if (token != null)
      client = GraphQLClient(
        link: HttpLink("https://graphql.anilist.co",
            defaultHeaders: {'Authorization': 'Bearer $token'}),
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

enum RequestType { recentlyUpdatedAnime, media, mutate }
