//contains base structure for a database

import 'package:animestream/core/database/types.dart';

enum Databases { anilist, simkl }

abstract class Database {
  Future<List<DatabaseSearchResult>> search(String query);
  Future<DatabaseInfo> getAnimeInfo(int id);
} 