//Call the database functions from this!

import 'package:animestream/core/database/anilist/anilist.dart';
import 'package:animestream/core/database/database.dart';
import 'package:animestream/core/database/simkl/simkl.dart';
import 'package:animestream/core/database/types.dart';

class DatabaseHandler extends Database {
  static Databases db = Databases.anilist;

  Database getActiveDatabaseInstance(Databases dbs) {
    switch (dbs) {
      case Databases.anilist:
        return Anilist();
      case Databases.simkl:
        return Simkl();
      default:
        throw Exception("NOT_AN_OPTION_LIL_BRO");
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
