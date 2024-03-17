import 'package:animestream/core/database/anilist/anilist.dart';
import 'package:animestream/core/database/anilist/types.dart';

class AnilistQueries {
  Future<List<UserAnimeList>> getUserAnimeList(String userName, {MediaStatus? status}) async {
    final query = '''query {
  MediaListCollection(userName: "$userName", type: ANIME ${status != null ? ", status: ${status.name}" : ''}) {
    lists {
      name
      entries {
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
        e = e['media'];
        animes.add(UserAnimeListItem(
          id: e['id'],
          title: {
            'english': e['title']['english'],
            'romaji': e['title']['romaji'],
          },
          coverImage: e['coverImage']['large'],
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
