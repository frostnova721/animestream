import "package:animestream/core/database/anilist/login.dart";
import "package:animestream/core/database/anilist/queries.dart";
import "package:animestream/core/database/anilist/types.dart";
import "package:animestream/ui/models/cards.dart";
import "package:hive/hive.dart";

Future<void> storeWatching(
    String title, String imageUrl, int id, int watched) async {
  try {
    //add to anilist if the user is logged in
    if (await AniListLogin().isAnilistLoggedIn()) {
      // final
    } else {
      var box = await Hive.openBox('animestream');
      if (!box.isOpen) {
        box = await Hive.openBox('animestream');
      }
      final List watchingList = box.get('watching') ?? [];
      final currList = watchingList.where((item) => item['id'] == id).toList();
      if (currList.length != 0 && currList[0]['watched'] <= watched) {
        watchingList.removeWhere((item) => item['id'] == id);
      }
      watchingList.add({
        'title': title,
        'imageUrl': imageUrl,
        'id': id,
        'watched': watched,
      });
      box.put('watching', watchingList);
      box.close();
    }
  } catch (err) {
    print(err);
  }
}

Future<void> updateWatching(String title, int watched) async {
  try {
    var box = await Hive.openBox('animestream');
    if (!box.isOpen) {
      box = await Hive.openBox('animestream');
    }
    final List watchingList = box.get('watching') ?? [];
    final index = watchingList.indexWhere((item) => item['title'] == title);
    if (index != -1) {
      watchingList[index]['watched'] = watched;
    } else {
      print('noData');
    }
    box.put('watching', watchingList);
    box.close();
  } catch (err) {
    print(err);
  }
}

Future<List<ListElement>> getWatched({String? userName}) async {
  final List<ListElement> recentlyWatched = [];
  if (await AniListLogin().isAnilistLoggedIn()) {
    if (userName != null) {
      List<UserAnimeList> watchedList = await AnilistQueries()
          .getUserAnimeList(userName, status: MediaStatus.CURRENT);
      final List<ListElement> widgeted = [];
       if (watchedList.length != 0) {
      if (watchedList.length > 20) watchedList = watchedList.sublist(0, 20);
      watchedList[0].list.forEach((element) {
        //idk why info is necessary :)
        widgeted.add(ListElement(
          widget: animeCard(
              element.title['english'] ?? element.title['romaji'] ?? '',
              element.coverImage),
          info: {"id":element.id},
        ));
      });
      return widgeted;
    }
    throw new Exception("ERR_USERNAME_NOT_PASSED");
    } 
  } else {
    final box = await Hive.openBox('animestream');
    List watching = box.get('watching') ?? [];

    if (watching.length != 0) {
      if (watching.length > 20) watching = watching.sublist(0, 20);
      watching.reversed.toList().forEach((e) {
        recentlyWatched.add(
            ListElement(widget: animeCard(e['title'], e['imageUrl']), info: e));
      });
    }
    box.close();
  }
  return recentlyWatched;
}
