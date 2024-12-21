//Call the database functions from this!

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/database/anilist/anilist.dart';
import 'package:animestream/core/database/database.dart';
import 'package:animestream/core/database/mal/mal.dart';
import 'package:animestream/core/database/simkl/simkl.dart';
import 'package:animestream/core/database/types.dart';

class DatabaseHandler extends Database {
  DatabaseHandler({Databases? database}) {
    if (database != null) {
      this.db = database;
    }
  }

  Databases db = currentUserSettings?.database ?? Databases.anilist;

  static Database getActiveDatabaseInstance(Databases dbs) {
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

  @override
  Future<List<DatabaseSearchResult>> search(String query) async {
    return await getActiveDatabaseInstance(db).search(query);
  }

  @override
  Future<DatabaseInfo> getAnimeInfo(int id) async {
    return await getActiveDatabaseInstance(db).getAnimeInfo(id);
  }
}
