import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/data/secureStorage.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/core/database/database.dart';
import 'package:animestream/core/database/mal/login.dart';
import 'package:animestream/core/database/mal/types.dart';
import 'package:animestream/core/database/types.dart';
import 'package:animestream/core/network/network.dart';

class MAL extends Database {
  @override
  Future<DatabaseInfo> getAnimeInfo(int id) {
    throw UnimplementedError();
  }

  @override
  Future<List<DatabaseSearchResult>> search(String query) {
    throw UnimplementedError();
  }

  static Map<String, String>? headers = null;

  static Future<Map<String, String>> getHeader(
      {bool refreshHeaders = false}) async {
    if (headers != null && !refreshHeaders) return headers!;
    final token = await getSecureVal(SecureStorageKey.malToken);
    final map = {
      'Authorization': "Bearer ${token}",
    };
    headers = map;
    return map;
  }

  Future<String> fetch(String url,
      {int recallAttempt = 0, bool refreshHeaders = false}) async {
    if (recallAttempt > 2)
      throw Exception("MAL-FETCH: MAX RECALL DEPTH LIMIT REACHED!");

    final headers = await getHeader(refreshHeaders: refreshHeaders);
    final res = await get(Uri.parse(url), headers: headers);

    // print(res.statusCode);

    if (res.statusCode == 401) {
      await MALLogin().refreshToken();
      return await fetch(url,
          recallAttempt: recallAttempt + 1, refreshHeaders: true);
    }

    //might have to remove this!
    if (res.statusCode != 200) {
      throw Exception("SOMETHING WRONG HAPPENED WHILE FETCHING MAL");
    }

    return res.body;
  }

  @override
  Future<DatabaseAnimeWatchProgress> getAnimeWatchProgress(int id) async {
    final url = "https://api.myanimelist.net/v2/anime/$id?fields=my_list_status";
    final res = await fetch(url);

    final datafied = MALAnimeWatchProgress.fromJson(res);
    return datafied;
  }

  @override
  Future<List<UserAnimeList>> getUserAnimeList(String userName, {List<MediaStatus>? status}) {
    // TODO: implement getUserAnimeList
    throw UnimplementedError();
  }
}
