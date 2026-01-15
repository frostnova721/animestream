import 'package:animestream/core/data/secureStorage.dart';
import 'package:animestream/core/database/anilist/anilist.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/core/commons/enums.dart';

class AnilistQueries {
  Future<List<UserAnimeList>> getUserAnimeList(String userName, {MediaStatus? status}) async {
    final query = '''query {
  MediaListCollection(userName: "$userName", type: ANIME ${status != null ? ", status: ${status.name}" : ''}, sort: UPDATED_TIME) {
    lists {
      name
      entries {
        progress
        media {
          id
          status
          episodes
          title {
            romaji
            english
            native
          }
          coverImage {
            large
          }
          averageScore
        }
      }
      status
    }
  }
}''';

    final res = await Anilist().fetchQuery(query, null);
    final List<dynamic> data = res['MediaListCollection']['lists'];
    final List<UserAnimeList> arrangedList = [];
    data.forEach((element) {
      final List<UserAnimeListItem> animes = [];
      element['entries'].forEach((e) {
        final media = e['media'];
        if (media != null) {
          animes.add(
            UserAnimeListItem(
              id: media['id'],
              title: {
                'english': media['title']?['english'],
                'romaji': media['title']?['romaji'],
                'native': media['title']?['native'],
              },
              // releaseStatus: media['status'],
              episodes: media['episodes'],
              coverImage: media['coverImage']['large'],
              watchProgress: e['progress'],
              rating: media['averageScore'] != null ? (media['averageScore'] / 10).toDouble() : null,
            ),
          );
        }
      });
      arrangedList.add(UserAnimeList(
        list: animes,
        name: element['name'],
        status: element['status'],
      ));
    });
    return arrangedList;
  }

  static String infoQuery(int anilistId) => '''
      {
        Page(perPage: 100) {
          media(id: $anilistId) {
            idMal
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
            averageScore
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
        id
        status
      }
    }
  }
}''';

  Future<List<AnilistRecommendations>> getRecommendedAnimes() async {
    final String query = '''{
  Page(perPage: 25) {
    recommendations(onList: true) {
      mediaRecommendation {
        id
        title {
          english
          romaji
          native
        }
        averageScore
        coverImage {
          large
        }
        type
      }
    }
  }
}''';
    final String? token = await getSecureVal(SecureStorageKey.anilistToken);
    final res = await Anilist().fetchQuery(query, null, token: token);
    final recommendations = res['Page']['recommendations'];
    List<AnilistRecommendations> recommendationList = [];
    for (final item in recommendations) {
      final rec = item['mediaRecommendation'];
      recommendationList.add(
        AnilistRecommendations(
          cover: rec['coverImage']['large'],
          id: rec['id'],
          title: {
            'english': rec['title']['english'],
            'romaji': rec['title']['romaji'],
            'native': rec['title']['native'],
          },
          rating: rec['averageScore'] is int ? rec['averageScore'] / 10 : null,
        ),
      );
    }
    return recommendationList;
  }

  Future<AnilistUserStats> getUserStats(String userName) async {
    final query = '''{
  User(name: "$userName") {
    statistics {
      anime {
        count
        minutesWatched
        episodesWatched
        genres {
          genre
          count
          minutesWatched
        }
      }
    }
  }
}''';

    final Map<String, dynamic> res = await Anilist().fetchQuery(query, null);
    final Map<String, dynamic> stats = res['User']['statistics']['anime'];
    List<GenreWatchStats> genres = [];
    for (final genre in stats['genres']) {
      genres
          .add(GenreWatchStats(count: genre['count'], genre: genre['genre'], minutesWatched: genre['minutesWatched']));
    }
    return AnilistUserStats(
      episodesWatched: stats['episodesWatched'],
      genres: genres,
      minutesWatched: stats['minutesWatched'],
      notInPlanned: stats['count'],
    );
  }

  // Future<List<AnimeCardData>> getGenrePopular(String genre) async {
  //   final query =
  //       """{ Page(perPage: 20){media(genre:"$genre", sort: POPULARITY_DESC, type: ANIME, countryOfOrigin:"JP") { id coverImage { large } title { english romaji } status } } }""";
  //   final res = await Anilist().fetchQuery(query, RequestType.media);
  //   List<AnimeCardData> genrePopular = [];
  //   for (final item in res) {
  //     genrePopular.add(
  //       AnimeCardData(
  //         cover: item['coverImage']['large'],
  //         id: item['id'],
  //         status: item['status'],
  //         title: {
  //           'english': item['title']['english'],
  //           'romaji': item['title']['romaji'],
  //         },
  //       ),
  //     );
  //   }

  //   return genrePopular;
  // }

  /// DONT. JUST DONT! Lots of entries, like 1000+. Infeasible to show in UI
  /// Code commented, Just In Case of a future change in idea
  // Future<List<Map<String, dynamic>>> getStudiosList() async {
  //   bool hasNext = false;

  //   final animstudios = <Map<String, dynamic>>[];
  //   int i = 0;

  //   do {
  //     try {
  //       i++;
  //       final q =
  //           """{Page(perPage: 100, page: $i) { pageInfo { hasNextPage } studios {id name isAnimationStudio } } }""";
  //       final res = await Anilist().fetchQuery(q, null);
  //       final List<Map<dynamic, dynamic>> items = List.castFrom(res['Page']?['studios'] ?? []);
  //       for (final item in items) {
  //         if (item['isAnimationStudio']) {
  //           animstudios.add({'id': item['id'], 'name': item['name']});
  //         }
  //       }
  //       hasNext = res['Page']?['pageInfo']?['hasNextPage'] ?? false;
  //       print("Page $i: done");
  //       await Future.delayed(Duration(milliseconds: 1200));
  //     } catch (err) {
  //       if (err is AnilistApiException) {
  //         if (err.statusCode == 429) {
  //           i--;
  //           print("Timeout err. wait a min");
  //           await Future.delayed(Duration(minutes: 1));
  //           continue;
  //         } else {
  //           print(err.toString());
  //           hasNext = false;
  //         }
  //       }
  //     }
  //   } while (hasNext);

  //   print("DONE");

  //   return animstudios;
  // }

  Future<List<AnimeCardData>> advancedSearch({
    List<String> genres = const [],
    List<String> tags = const [],
    int page = 1,
    int ratingLow = 0,
    int ratingHigh = 10,
    AnilistSortType sort = AnilistSortType.trendingDesc,
    String? query,
  }) async {
    String genreString = "";
    String tagString = "";
    if (genres.isNotEmpty) {
      genreString = "genre_in: " + genres.map((e) => '"$e"').toList().toString();
    }
    if (tags.isNotEmpty) {
      tagString = "tag_in: " + tags.map((e) => '"$e"').toList().toString();
    }

    final query =
        """{ Page(perPage: 30, page: $page){media(${genreString.isNotEmpty ? "${genreString}," : ''} ${tagString.isNotEmpty ? "${tagString}," : ''} \
        sort: ${sort.value}, type: ANIME, countryOfOrigin:"JP", averageScore_lesser: ${ratingHigh * 10}, averageScore_greater: ${ratingLow * 10}) { id coverImage { large } title { english romaji native } status averageScore } } }""";
    final res = await Anilist().fetchQuery(query, RequestType.media);
    List<AnimeCardData> results = [];
    for (final item in res) {
      results.add(
        AnimeCardData(
          cover: item['coverImage']['large'],
          id: item['id'],
          status: item['status'],
          rating: item['averageScore'] is int ? item['averageScore'] / 10 : null,
          title: {
            'english': item['title']['english'],
            'romaji': item['title']['romaji'],
            'native': item['title']['native'],
          },
        ),
      );
    }

    return results;
  }

  // Future<List<AnimeCardData>> getGenreTrending(String genre) async {
  //   final query =
  //       """{ Page(perPage: 20){media(genre:"$genre", sort: TRENDING_DESC, type: ANIME, countryOfOrigin:"JP") { id coverImage { large } title { english romaji } status } } }""";
  //   final res = await Anilist().fetchQuery(query, RequestType.media);
  //   List<AnimeCardData> genreTrending = [];
  //   for (final item in res) {
  //     genreTrending.add(
  //       AnimeCardData(
  //         cover: item['coverImage']['large'],
  //         id: item['id'],
  //         status: item['status'],
  //         title: {
  //           'english': item['title']['english'],
  //           'romaji': item['title']['romaji'],
  //         },
  //         rating: item['averageScore'] is int ? item['averageScore']/10 : null,
  //       ),
  //     );
  //   }

  //   return genreTrending;
  // }

  Future<List<String>> getGenreThumbnail(String genre) async {
    final query =
        """{ Page(perPage: 10){media(genre:"$genre", status: RELEASING, sort: TRENDING_DESC, type: ANIME, countryOfOrigin:"JP") {bannerImage} } }""";
    final res = await Anilist().fetchQuery(query, RequestType.media);
    List<String> banners = [];
    for (final item in res) {
      if (item['bannerImage'] != null) {
        banners.add(item['bannerImage']);
      }
    }
    return banners;
  }
}
