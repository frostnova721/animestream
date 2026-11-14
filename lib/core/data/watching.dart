import "package:animestream/core/app/logging.dart";
import "package:animestream/core/commons/enums.dart";
import "package:animestream/core/commons/utils.dart";
import "package:animestream/core/database/anilist/types.dart";
import "package:animestream/core/database/handler/handler.dart";
import "package:animestream/core/database/handler/syncHandler.dart";
import "package:animestream/core/database/local/local.dart";
import "package:animestream/core/database/local/types.dart";
import "package:animestream/core/database/types.dart";

Future<void> storeWatching(
  String title,
  String imageUrl,
  int id,
  int watched, {
  int? totalEpisodes,
  List<AlternateDatabaseId>? alternateDatabases,
  double? rating,
  Map<String, String?>? titles,
}) async {
  try {
    //add to anilist if the user is logged in
    Logs.app.log("SETTING WATCHED TO $watched");
    SyncHandler().mutateAnimeList(
      id: id,
      status: MediaStatus.CURRENT,
      progress: watched,
      otherIds: alternateDatabases,
      meta: LocalMeta(
        title: titles ?? {'english': title},
        cover: imageUrl,
        totalEpisodes: totalEpisodes,
        rating: rating,
      ),
    );
  } catch (err) {
    Logs.app.log(err.toString());
  }
}

Future<void> updateWatching(int id, String title, int watched, List<AlternateDatabaseId> otherIds) async {
  try {
    Logs.app.log("UPDATING WATCHED TO $watched");

    SyncHandler().mutateAnimeList(
      id: id,
      status: MediaStatus.CURRENT,
      previousStatus: MediaStatus.CURRENT,
      progress: watched,
      otherIds: otherIds,
    );
  } catch (err) {
    Logs.app.log(err.toString());
  }
}

Future<List<UserAnimeListItem>> getWatchedList({String? userName}) async {
  final tracker = await DatabaseHandler.getActiveTracker();
  if (tracker is! LocalTracker && userName == null) {
    throw Exception("Username is required for non-local trackers");
  }
  final list = await tracker.getUserAnimeList(userName ?? "", status: [MediaStatus.CURRENT]);
  return list.isEmpty ? [] : list.first.list.reversed.toList();
}

/// Returns the watch progress and media status. -1 is returned if entry doesnt exist
Future<(int, MediaStatus?)> getAnimeWatchProgress(int id) async {
  final item = await (await DatabaseHandler.getActiveTracker()).getAnimeWatchProgress(id);
  return (item.progress ?? 0, assignItemEnum(item.status));
}
