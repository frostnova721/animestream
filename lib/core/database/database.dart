//contains base structure for a database

import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/database/types.dart';

enum Databases {
  anilist,
  mal,
  simkl;
}

class DatabaseFromString {
  static Databases getDb(String dbString) {
    switch (dbString) {
      case "anilist":
        return Databases.anilist;
      case "simkl":
        return Databases.simkl;
      case "mal":
        return Databases.mal;
      default:
        return Databases.anilist;
    }
  }
}

abstract class DatabaseLogin {
  Future<bool> initiateLogin();
  Future<void> removeToken();
  Future<void>? refreshToken();
}

abstract class Database {
  Future<List<DatabaseSearchResult>> search(String query);

  Future<DatabaseInfo> getAnimeInfo(int id);
}

abstract class DatabaseMutation {
  Future<DatabaseMutationResult?> mutateAnimeList(
      {required int id, MediaStatus? status = MediaStatus.CURRENT, int? progress = 0, MediaStatus? previousStatus});
}
