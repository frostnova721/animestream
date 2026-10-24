import 'dart:convert';
import 'dart:io';

import 'package:animestream/core/app/env.dart';
import 'package:animestream/core/app/logging.dart';
import 'package:animestream/core/app/version.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/core/database/database.dart';
import 'package:animestream/core/database/simkl/types.dart';
import 'package:animestream/core/database/types.dart';
import 'package:animestream/core/network/network.dart';

class Simkl extends Database {
  static final _appHeader = "app-name=animestream&app-version=${AppVersion.instance.version}";

  static String imageLink(String url, {bool fanart = false}) =>
      "https://wsrv.nl/?url=https://simkl.in/${fanart ? "fanart" : "posters"}/${url}${fanart ? "_w" : "_ca"}.webp";

  /// Resolves the Simkl ID using Simkl's modern Cloudflare-cached /redirect endpoint.
  /// Follows 0 redirects and extracts the canonical Simkl ID directly from the Location header.
  Future<int?> getIdFromRedirect({int? anilistId, int? malId}) async {
    try {
      final queryParam = anilistId != null ? 'anilist=$anilistId' : (malId != null ? 'mal=$malId' : null);
      if (queryParam == null) return null;

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);
      final uri = Uri.parse("https://api.simkl.com/redirect?$queryParam");
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 4));
      request.followRedirects = false;
      final response = await request.close().timeout(const Duration(seconds: 4));
      final location = response.headers.value(HttpHeaders.locationHeader);
      client.close();

      if (location != null) {
        final match = RegExp(r'/anime/(\d+)').firstMatch(location);
        if (match != null) {
          return int.tryParse(match.group(1)!);
        }
      }
    } catch (e) {
      Logs.app.log("[SIMKL] getIdFromRedirect failed: $e");
    }
    return null;
  }

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

  @override
  Future<DatabaseAnimeWatchProgress> getAnimeWatchProgress(int id) {
    // TODO: implement getAnimeWatchProgress
    throw UnimplementedError();
  }

  @override
  Future<List<UserAnimeList>> getUserAnimeList(String userName, {MediaStatus? status}) {
    // TODO: implement getUserAnimeList
    throw UnimplementedError();
  }
}
