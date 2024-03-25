import "package:animestream/core/app/runtimeDatas.dart";
import "package:animestream/core/database/anilist/login.dart";
import "package:animestream/core/database/anilist/mutations.dart";
import "package:animestream/core/database/anilist/queries.dart";
import "package:animestream/core/database/anilist/types.dart";
import 'package:animestream/core/commons/enums.dart';
import "package:hive/hive.dart";

Future<void> storeWatching(
    String title, String imageUrl, int id, int watched) async {
  try {
    //add to anilist if the user is logged in
    print("SETTING WATCHED TO $watched");
    if (await AniListLogin().isAnilistLoggedIn()) {
      AnilistMutations().mutateAnimeList(
          id: id, status: MediaStatus.CURRENT, progress: watched);
    } else {
      var box = await Hive.openBox('animestream');
      if (!box.isOpen) {
        box = await Hive.openBox('animestream');
      }
      final List watchingList = box.get('watching') ?? [];
      // final currList = watchingList.where((item) => item['id'] == id).toList();
      // if (currList.length != 0 && currList[0]['watched'] <= watched) {
        watchingList.removeWhere((item) => item['id'] == id);
      // }
      watchingList.add({
        'title': title,
        'imageUrl': imageUrl,
        'id': id,
        'watched': watched,
      });
      print(watchingList);
      box.put('watching', watchingList);
      box.close();
    }
  } catch (err) {
    print(err);
  }
}

Future<void> updateWatching(int? id, String title, int watched) async {
  try {
    print("UPDATING WATCHED TO $watched");
    if (await AniListLogin().isAnilistLoggedIn()) {
      if (id == null) throw new Exception("ERR_NO_ID_PROVIDED");
      AnilistMutations().mutateAnimeList(
        id: id,
        status: MediaStatus.CURRENT,
        progress: watched,
      );
    } else {
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
    }
  } catch (err) {
    print(err);
  }
}

Future<List<UserAnimeListItem>> getWatchedList({String? userName}) async {
  final List<UserAnimeListItem> recentlyWatched = [];
  if (await AniListLogin().isAnilistLoggedIn()) {
    if (userName != null) {
      List<UserAnimeList> watchedList = await AnilistQueries()
          .getUserAnimeList(userName, status: MediaStatus.CURRENT);
      final list = watchedList[0].list.reversed.toList();
      if (list.length != 0) {
        return list;
      } else {
        throw new Exception("COULDNT_FIND_ANY_ANIMES_IN_CURRENT");
      }
    }
    throw new Exception("ERR_USERNAME_NOT_PASSED");
  } else {
    final box = await Hive.openBox('animestream');
    List watching = box.get('watching') ?? [];

    if (watching.length != 0) {
      watching.reversed.toList().forEach((e) {
        recentlyWatched.add(UserAnimeListItem(
          id: e['id'],
          //just give the key as title since its just one
          title: {
            'title': e['title']
          },
          coverImage: e['imageUrl'],
          watchProgress: e['watched'],
          rating: e['rating'] ?? null,
        ));
      });
      box.close();
    }
    return recentlyWatched;
  }
}

Future<int> getAnimeWatchProgress(int id, MediaStatus status) async {
  if (await AniListLogin().isAnilistLoggedIn()) {
    if(storedUserData == null) throw new Exception("ERR_NO_USERDATA");
    print(status);
    final list = await AnilistQueries().getUserAnimeList(storedUserData!.name, status: status);
    if(list.isEmpty) throw new Exception("ERR_${status.name.toUpperCase()}_LIST_IS_EMPTY");
    else {
    final item = list[0].list.where((item) => item.id == id).firstOrNull;
    if(item != null) return item.watchProgress ?? 0;
    }
  } else {
    final box = await Hive.openBox('animestream');
    final List watching = box.get('watching') ?? [];
    final item = watching.where((item) => item['id'] == id).firstOrNull;
    await box.close();
    if (item != null) {
      return item['watched'];
    }
  }
  return 0;
}
