import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/database/anilist/mutations.dart';
import 'package:animestream/core/database/database.dart';
import 'package:animestream/core/database/mal/mutations.dart';
import 'package:animestream/core/database/simkl/mutations.dart';
import 'package:animestream/core/database/types.dart';

class SyncHandler extends DatabaseMutation {
  @override
  Future<DatabaseMutationResult?> mutateAnimeList({
    required int id,
    List<AlternateDatabaseId>? otherIds,
    MediaStatus? status,
    MediaStatus? previousStatus,
    int? progress,
  }) async {
    final List<Databases> databases = Databases.values;
    final activedb = getActiveDatabase();
    final activeDbInstance = getDatabaseMutationInstance(activedb);

    //sync with the active database first
    activeDbInstance
        .mutateAnimeList(id: id, status: status, previousStatus: previousStatus, progress: progress)
        .then((val) => print("[SYNC HANDLER]: Synced ${activedb.name}"))
        .catchError((e, st) {
      print(e);
      print(st.toString());
      return null;
    });

    //sync with other databases
    otherIds?.forEach((it) {
      if (it.database != activedb) {
        final altdb = databases.where((db) => db == it.database).firstOrNull;
        if (altdb != null) {
          final mutInstance = getDatabaseMutationInstance(altdb);
          mutInstance
              .mutateAnimeList(id: it.id, status: status, previousStatus: previousStatus, progress: progress)
              .then((val) => print("[SYNC HANDLER]: Synced ${it.database.name}"))
              .catchError((e, st) {
            print(e);
            print(st.toString());
            return null;
          });
        }
      }
    });

    return null;
  }

  @override
  Future<DatabaseMutationResult?> deleteAnimeEntry({required int id, List<AlternateDatabaseId>? otherIds}) async {
    final List<Databases> databases = Databases.values;
    final activedb = getActiveDatabase();
    final activeDbInstance = getDatabaseMutationInstance(activedb);

    //sync with the active database first
    activeDbInstance
        .deleteAnimeEntry(id: id)
        .then((val) => print("[SYNC HANDLER]: Deleted from ${activedb.name}"))
        .catchError((e, st) {
      print(e);
      print(st.toString());
      return null;
    });

    //sync with other databases
    otherIds?.forEach((it) {
      if (it.database != activedb) {
        final altdb = databases.where((db) => db == it.database).firstOrNull;
        if (altdb != null) {
          final mutInstance = getDatabaseMutationInstance(altdb);
          mutInstance
              .deleteAnimeEntry(id: it.id)
              .then((val) => print("[SYNC HANDLER]: Deleted from ${it.database.name}"))
              .catchError((e, st) {
            print(e);
            print(st.toString());
            return null;
          });
        }
      }
    });

    return null;
  }

  DatabaseMutation getDatabaseMutationInstance(Databases db) {
    switch (db) {
      case Databases.anilist:
        return AnilistMutations();
      case Databases.simkl:
        return SimklMutation();
      case Databases.mal:
        return MALMutation();
      // default:
      // throw Exception("NOT_AN_OPTION_LIL_BRO");
    }
  }

  //get the preferred/current database
  Databases getActiveDatabase() {
    return currentUserSettings?.database ?? Databases.anilist;
  }
}
