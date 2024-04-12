import 'package:animestream/core/commons/utils.dart';
import 'package:animestream/core/data/hive.dart';
import 'package:animestream/core/database/anilist/anilist.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/core/commons/enums.dart';

class AnilistQueries {
  Future<List<UserAnimeList>> getUserAnimeList(String userName,
      {MediaStatus? status}) async {
    final query = '''query {
  MediaListCollection(userName: "$userName", type: ANIME ${status != null ? ", status: ${status.name}" : ''}, sort: UPDATED_TIME) {
    lists {
      name
      entries {
        progress
        media {
          id
          title {
            romaji
            english
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
        animes.add(
          UserAnimeListItem(
            id: media['id'],
            title: {
              'english': media['title']['english'],
              'romaji': media['title']['romaji'],
            },
            coverImage: media['coverImage']['large'],
            watchProgress: e['progress'],
            rating: media['averageScore'] != null
                ? (media['averageScore'] / 10)?.toDouble()
                : null,
          ),
        );
      });
      arrangedList.add(UserAnimeList(
        list: animes,
        name: element['name'],
        status: element['status'],
      ));
    });
    return arrangedList;
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
    final String? token = await getVal("token");
    final result =
        await Anilist().fetchQuery(query, RequestType.media, token: token);

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
        tags: tags,
        mediaListStatus: info['mediaListEntry']?['status'],
      );

      return convertedGuy;
    }

    return convertToIAnimeDetails();
  }
}
