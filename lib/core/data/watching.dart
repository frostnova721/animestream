import "package:hive/hive.dart";

import "package:animestream/core/app/logging.dart";
import "package:animestream/core/app/runtimeDatas.dart";
import "package:animestream/core/commons/enums/hiveEnums.dart";
import "package:animestream/core/database/anilist/login.dart";
import "package:animestream/core/database/anilist/queries.dart";
import "package:animestream/core/database/anilist/types.dart";
import "package:animestream/core/database/handler/syncHandler.dart";
import "package:animestream/core/database/types.dart";
import "package:animestream/core/commons/enums.dart";

final String _boxName = HiveBox.animestream.boxName;

Future<void> storeWatching(
  String title,
  String imageUrl,
  int id,
  int watched, {
  int? totalEpisodes,
  List<AlternateDatabaseId>? alternateDatabases,
  double? rating,
}) async {
  try {
    //add to anilist if the user is logged in
    Logs.app.log("SETTING WATCHED TO $watched");
    if (await AniListLogin().isAnilistLoggedIn()) {
      SyncHandler()
          .mutateAnimeList(id: id, status: MediaStatus.CURRENT, progress: watched, otherIds: alternateDatabases);
    } else {
      var box = await Hive.openBox(_boxName);
      if (!box.isOpen) {
        box = await Hive.openBox(_boxName);
      }
      final List<dynamic> watchingList = List.castFrom(box.get('watching') ?? []);
      // final currList = watchingList.where((item) => item['id'] == id).toList();
      // if (currList.length != 0 && currList[0]['watched'] <= watched) {
      watchingList.removeWhere((item) => item['id'] == id);
      // }
      watchingList.add({
        'title': title,
        'imageUrl': imageUrl,
        'id': id,
        'watched': watched,
        'rating': rating,
        'totalEpisodes': totalEpisodes,
      });
      // print(watchingList);
      box.put('watching', watchingList);
      box.close();
    }
  } catch (err) {
    Logs.app.log(err.toString());
  }
}

Future<void> updateWatching(int? id, String title, int watched, List<AlternateDatabaseId> otherIds) async {
  try {
    Logs.app.log("UPDATING WATCHED TO $watched");
    if (await AniListLogin().isAnilistLoggedIn()) {
      if (id == null) throw Exception("ERR_NO_ID_PROVIDED");
      SyncHandler().mutateAnimeList(
        id: id,
        status: MediaStatus.CURRENT,
        previousStatus: MediaStatus.CURRENT,
        progress: watched,
        otherIds: otherIds,
      );
    } else {
      var box = await Hive.openBox(_boxName);
      if (!box.isOpen) {
        box = await Hive.openBox(_boxName);
      }
      final List<dynamic> watchingList = List.castFrom(box.get('watching') ?? []);
      final index = watchingList.indexWhere((item) => item['title'] == title);
      if (index != -1) {
        watchingList[index]['watched'] = watched;
      } else {
        Logs.app.log("Anime entry doesn't exists to make progress update");
      }
      box.put('watching', watchingList);
      box.close();
    }
  } catch (err) {
    Logs.app.log(err.toString());
  }
}

Future<List<UserAnimeListItem>> getWatchedList({String? userName}) async {
  final List<UserAnimeListItem> recentlyWatched = [];
  if (await AniListLogin().isAnilistLoggedIn()) {
    if (userName != null) {
      List<UserAnimeList> watchedList = await AnilistQueries().getUserAnimeList(userName, status: MediaStatus.CURRENT);
      if (watchedList.isEmpty) {
        return [];
      }
      // reversing it to get the last updated item first :)
      final list = watchedList[0].list.reversed.toList();
      return list;
    }
    throw Exception("ERR_USERNAME_IS_NULL");
  } else {
    final box = await Hive.openBox(_boxName);
    List<dynamic> watching = List.castFrom(box.get('watching') ?? []);

    if (watching.isNotEmpty) {
      for(final e in watching.reversed) {
        recentlyWatched.add(UserAnimeListItem(
            id: e['id'],
            //just give the key as title since its just one
            title: {'title': e['title']},
            coverImage: e['imageUrl'],
            watchProgress: e['watched'],
            rating: e['rating'],
            episodes: e['totalEpisodes']));
      }
    }
    box.close();
    return recentlyWatched;
  }
}

Future<int> getAnimeWatchProgress(int id, MediaStatus? status) async {
  if (await AniListLogin().isAnilistLoggedIn() && status != null) {
    if (storedUserData == null) throw Exception("ERR_NO_USERDATA");
    final list = await AnilistQueries().getUserAnimeList(storedUserData!.name, status: status);
    if (list.isEmpty) {
      throw Exception("ERR_${status.name.toUpperCase()}_LIST_IS_EMPTY");
    } else {
      final item = list[0].list.where((item) => item.id == id).firstOrNull;
      return item?.watchProgress ?? 0;
    }
  } else {
    final box = await Hive.openBox(_boxName);
    final List<dynamic> watching = List.castFrom(box.get('watching') ?? []);
    final item = watching.where((item) => item['id'] == id).firstOrNull;
    await box.close();
    if (item != null) {
      return item['watched'];
    }
  }
  return 0;
}
