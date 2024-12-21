import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/data/secureStorage.dart';
import 'package:animestream/core/database/database.dart';
import 'package:animestream/core/database/mal/login.dart';
import 'package:animestream/core/database/types.dart';
import 'package:http/http.dart';

class MAL extends Database {
  @override
  Future<DatabaseInfo> getAnimeInfo(int id) {
    // TODO: implement getAnimeInfo
    throw UnimplementedError();
  }

  @override
  Future<List<DatabaseSearchResult>> search(String query) {
    // TODO: implement search
    throw UnimplementedError();
  }
  
  static Future<Map<String, String>> getHeader() async {
    final token = await getSecureVal(SecureStorageKey.malToken);
    return {
      'Content-Type': "application/json",
      'Authorization': "Bearer ${token}",
    };
  }

  Future<String> fetch(String url, {int recallAttempt = 0 }) async {

    if(recallAttempt > 2) throw Exception("MAX RECALL DEPTH LIMIT REACHED!");

    final headers = await getHeader();
    final res = await get(Uri.parse(url), headers: headers);

    if(res.statusCode == 200) {
      throw Exception("SOMETHING WRONG HAPPENED WHILE FETCHING MAL");
    }

    if(res.statusCode == 401) {
      await MALLogin().refreshToken();
      return await fetch(url, recallAttempt: recallAttempt++);
    }

    return res.body;  
  }
}