import 'dart:convert';

import 'package:animestream/core/app/env.dart';
import 'package:animestream/core/app/version.dart';
import 'package:animestream/core/database/database.dart';
import 'package:animestream/core/database/simkl/types.dart';
import 'package:animestream/core/network/network.dart';

class Simkl extends Database {
  static final _appHeader = "app-name=animestream&app-version=${AppVersion.instance.version}";

  static String imageLink(String url, {bool fanart = false}) =>
      "https://wsrv.nl/?url=https://simkl.in/${fanart ? "fanart" : "posters"}/${url}${fanart ? "_w" : "_ca"}.webp";

  Future<List<SimklSearchResult>> search(String query) async {
    final url =
        "https://api.simkl.com/search/anime?q=$query&client_id=${AnimeStreamEnvironment.simklClientId}&$_appHeader";
    final List<dynamic> res = await fetch(url);
    List<SimklSearchResult> sr = [];
    res.forEach((it) {
      sr.add(SimklSearchResult(
        cover: imageLink(it['poster']),
        id: it['ids']['simkl_id'],
        title: {
          'english': it['title_en'] ?? it['title'],
          'romaji': it['title_romaji'] ?? it['title']
        },
      ));
    });

    return sr;
  }

  Future<SimklInfo> getAnimeInfo(int id) async {
    final url =
        "https://api.simkl.com/anime/$id?extended=full&client_id=${AnimeStreamEnvironment.simklClientId}&$_appHeader";
    final res = await fetch(url);
    final datafied = SimklInfo.fromJson(res);
    return datafied;
  }

  Future<dynamic> fetch(String url) async {
    final res = await get(Uri.parse(url));

    //since 2** means success
    if (res.statusCode < 200 || res.statusCode > 299) {
      throw Exception("ERR_COULDNT_FETCH_SIMKL");
    }
    return jsonDecode(res.body);
  }
}
