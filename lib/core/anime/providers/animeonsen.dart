import 'dart:convert';

import 'package:animestream/core/anime/providers/types.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/commons/types.dart';
import 'package:animestream/core/data/hive.dart';
import 'package:animestream/ui/models/subtitles.dart';
import 'package:http/http.dart';

class AnimeOnsen extends AnimeProvider {
  Future<void> checkAndUpdateToken() async {
    final Map<dynamic, dynamic> currentToken = await getVal(HiveKey.animeOnsenToken, boxName: "misc") ?? {};
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000;

    //get the new token if the old one is expired
    if ((currentToken.isNotEmpty && (currentToken['expiration'] < (currentTime + 3600))) || currentToken.isEmpty) {
      print("[PROVIDER] Generating new animeonsen token");
      final token = await getToken();
      final modifiedMap = {
        'token': token['token'],
        'expiration': token['expiration'] + currentTime,
      };
      await storeVal(HiveKey.animeOnsenToken, modifiedMap, boxName: "misc");
      animeOnsenToken = token['token'];
      print("[PROVIDER] AO Token Saved!");
    } else {
      //just save the current token in a variable
      animeOnsenToken = currentToken['token'];
    }
  }

  Future<Map<String, dynamic>> getToken() async {
    final url = "https://auth.animeonsen.xyz/oauth/token";

    //thanks aniyomi extensions!
    final body = {
        "client_id": "f296be26-28b5-4358-b5a1-6259575e23b7",
        "client_secret": "349038c4157d0480784753841217270c3c5b35f4281eaee029de21cb04084235",
        "grant_type": "client_credentials"
    };
    final res = await post(Uri.parse(url), body: body);

    if (res.statusCode != 200) {
      throw new Exception("Exception: couldnt generate AO token");
    }

    final Map<String, dynamic> jsoned = jsonDecode(res.body);
    return {'expiration': jsoned['expires_in']!, 'token': jsoned['access_token']!};
  }

  @override
  Future<List<String>> getAnimeEpisodeLink(String aliasId) async {
    final baseUrl = 'https://api.animeonsen.xyz/v4/content/${aliasId}/episodes';
    final apiHeader = {
      "Authorization": "Bearer $animeOnsenToken",
    };
    final res = await get(Uri.parse(baseUrl), headers: apiHeader);
    final Map<String, dynamic> jsoned = jsonDecode(res.body);

    List<String> episodes = [];

    for (final item in jsoned.keys) {
      //we adding this as combination of alias and ep num
      episodes.add("$item+$aliasId");
    }

    return episodes;
  }

  @override
  Future<void> getStreams(String episodeId, Function(List<Stream> p1, bool p2) update) async {
    final animeId = episodeId.split("+")[1];
    final episodeNumber = episodeId.split("+")[0];
    final baseUrl = "https://cdn.animeonsen.xyz/video/mp4-dash/${animeId}/${episodeNumber}/manifest.mpd";
    final subtitleUrl = "https://api.animeonsen.xyz/v4/subtitles/${animeId}/en-US/${episodeNumber}";
    final result = Stream(
        quality: "single",
        link: baseUrl,
        isM3u8: false,
        server: "animeonsen",
        backup: false,
        subtitle: subtitleUrl,
        subtitleFormat: SubtitleFormat.ASS);

    update([result], true);
  }

  @override
  Future<List<Map<String, String?>>> search(String query) async {
    final baseUrl = "https://api.animeonsen.xyz/v4/search/$query";

    final headers = {
      "Authorization": "Bearer $animeOnsenToken",
    //   "Content-Type": "application/json",
    };

    final res = await get(Uri.parse(baseUrl), headers: headers);

    final List<Map<String, String>> searchResults = [];

    final jsoned = jsonDecode(res.body);

    jsoned['result'].forEach((item) {
      searchResults.add({
        'name': item['content_title_en'] ?? item['content_title'],
        'alias': item['content_id'],
        'imageUrl': "https://api.animeonsen.xyz/v4/image/210x300/${item['content_id']}",
      });
    });

    return searchResults;
  }
  
  @override
  Future<void> getDownloadSources(String episodeUrl, Function(List<Stream> p1, bool p2) update) {
     throw UnimplementedError();
  }
}
