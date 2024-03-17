import 'package:animestream/core/database/anilist/anilist.dart';
import 'package:animestream/core/database/anilist/types.dart';

class AnilistQueries {
  Future<List<UserAnimeList>> getUserAnimeList(String userName, {MediaStatus? status}) async {
    final query = '''query {
  MediaListCollection(userName: "$userName", type: ANIME ${status != null ? ", status: ${status.name}" : ''}) {
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
        animes.add(UserAnimeListItem(
          id: media['id'],
          title: {
            'english': media['title']['english'],
            'romaji': media['title']['romaji'],
          },
          coverImage: media['coverImage']['large'],
          watchProgress: e['progress']
        ));
      });
      arrangedList.add(UserAnimeList(
        list: animes,
        name: element['name'],
        status: element['status'],
      ));
    });
    return arrangedList;
  }
}
