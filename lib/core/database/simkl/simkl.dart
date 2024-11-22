import 'dart:convert';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/database/database.dart';
import 'package:animestream/core/database/simkl/types.dart';
import 'package:http/http.dart';

class Simkl extends Database {
  static String _imageLink(String url) => "https://wsrv.nl/?url=https://simkl.in/posters/${url}_ca.webp";

  Future<List<SimklSearchResult>> search(String query) async {
    final url = "https://api.simkl.com/search/anime?q=$query&client_id=$simklClientId";
    final List<dynamic> res = await fetch(url);
    List<SimklSearchResult> sr = [];
    res.forEach((it) {
      sr.add(SimklSearchResult(
        cover: _imageLink(it['poster']),
        id: it['ids']['simkl_id'],
        title: {'english': it['title_en'] ?? it['title'], 'romaji': it['title_romaji'] ?? it['title']},
      ));
    });

    return sr;
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
