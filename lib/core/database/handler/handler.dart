//Call the database functions from this!

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/database/anilist/anilist.dart';
import 'package:animestream/core/database/anilist/login.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/core/database/database.dart';
import 'package:animestream/core/database/local/local.dart';
import 'package:animestream/core/database/mal/login.dart';
import 'package:animestream/core/database/mal/mal.dart';
import 'package:animestream/core/database/simkl/login.dart';
import 'package:animestream/core/database/simkl/simkl.dart';
import 'package:animestream/core/database/types.dart';

class DatabaseHandler extends Database {
  DatabaseHandler({Databases? database}) {
    if (database != null) {
      this.db = database;
    }
  }

  Databases db = currentUserSettings?.database ?? Databases.anilist;

  static Database getDatabaseInstance(Databases dbs) {
    switch (dbs) {
      case Databases.anilist:
        return Anilist();
      case Databases.simkl:
        return Simkl();
      case Databases.mal:
        return MAL();
      // default:
      //   throw Exception("NOT_AN_OPTION_LIL_BRO");
    }
  }

  static DatabaseLogin getDatabaseLoginInstance(Databases dbs) {
    switch (dbs) {
      case Databases.anilist:
        return AnilistLogin();
      case Databases.simkl:
        return SimklLogin();
      case Databases.mal:
        return MALLogin();
      // default:
      //   throw Exception("NOT_AN_OPTION_LIL_BRO");
    }
  }

  // Yes ik it is repetitive code! stfu
  static Tracker getTrackerInstance(Databases dbs) {
    switch (dbs) {
      case Databases.anilist:
        return Anilist();
      case Databases.simkl:
        return Simkl();
      case Databases.mal:
        return MAL();
    }
  }

  static Tracker? _activeTracker;

  static Future<Tracker> getActiveTracker() async {
    if (_activeTracker != null) return _activeTracker!;
    final db = currentUserSettings?.database ?? Databases.anilist;
    final tracker = await getDatabaseLoginInstance(db).isLoggedIn() ? getTrackerInstance(db) : LocalTracker();
    _activeTracker = tracker;
    return tracker;
  }

  static void invalidateTracker() => _activeTracker = null;

  Future<bool> isLoggedIn() async {
    return await getDatabaseLoginInstance(db).isLoggedIn();
  }

  @override
  Future<List<DatabaseSearchResult>> search(String query) async {
    return await getDatabaseInstance(db).search(query);
  }

  @override
  Future<DatabaseInfo> getAnimeInfo(int id) async {
    return await getDatabaseInstance(db).getAnimeInfo(id);
  }

  @override
  Future<DatabaseAnimeWatchProgress> getAnimeWatchProgress(int id) async {
    return await (await getActiveTracker()).getAnimeWatchProgress(id);
  }

  @override
  Future<List<UserAnimeList>> getUserAnimeList(String userName, {List<MediaStatus>? status}) async {
    return await (await getActiveTracker()).getUserAnimeList(userName, status: status);
  }
}
