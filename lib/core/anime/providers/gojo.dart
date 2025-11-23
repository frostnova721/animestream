import 'dart:convert';

import 'package:animestream/core/anime/providers/animeProvider.dart';
import 'package:animestream/core/anime/providers/types.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/database/anilist/anilist.dart';
import 'package:http/http.dart';

//use anilist for searching
class Gojo extends AnimeProvider {
  static const String apiUrl = "https://backend.animetsu.cc/api/anime";

  final baseUrl = "https://animetsu.cc";

  final headers = {
    'Origin': 'https://animetsu.cc',
    'Referer': 'https://animetsu.cc/',
  };

  @override
  final String providerName = "gojo";

  @override
  Future<List<Map<String, String>>> search(String query) async {
    final res = await Anilist().search(query);
    final List<Map<String, String>> sr = [];
    for (final item in res) {
      sr.add({
        'name': item.title['english'] ?? item.title['romaji'] ?? '',
        'alias': item.id.toString(),
        'imageUrl': item.cover,
      });
    }

    return sr;
  }

  @override
  Future<List<Map<String, dynamic>>> getAnimeEpisodeLink(String aliasId, {bool dub = false}) async {
    //alias id here is the anilist id

    final url = Uri.parse("$apiUrl/eps/$aliasId");
    final res = await get(url, headers: headers);
    final List<Map<String, dynamic>> json = List.castFrom(jsonDecode(res.body));
    final newSht = json.map<Map<String, dynamic>>((item) {
      final int epNum = item['number']?.toInt();
      final bool isFiller = item['isFiller'];
      final String? img = item['image'];
      final String? title = item['title'];

      return {
        'episodeLink': "$aliasId", // used for getting other stuff
        'episodeNumber': epNum,
        'filler': isFiller,
        'thumbnail': img,
        'episodeTitle': title,
        'hasDub': true,
        'metadata': "$epNum",
      };
    }).toList();

    return newSht;
  }

  @override
  Future<void> getStreams(String epLink, Function(List<VideoStream> list, bool isFinished) update,
      {bool dub = false, String? metadata}) async {
    final id = epLink;
    final epNum = metadata;
    if (metadata == null) throw Exception("Couldnt get streams, required field metadata recieved null.");

    final List<Future<Response>> futures = [];

    final serverList = await get(Uri.parse("$apiUrl/servers?id=$id&num=$epNum"), headers: headers);
    final List<Map<String, dynamic>> serversJson = List.castFrom(jsonDecode(serverList.body));
    print(serversJson);
    serversJson.forEach((it) {
      final url = "$apiUrl/tiddies?server=${it['id']}&id=$id&num=$epNum&subType=${dub ? "dub" : "sub"}";
      final res = get(Uri.parse(url), headers: headers);
      futures.add(res);
    });

    final its = await futures.wait;

    int doneSources = 0;
    final int totalSources = futures.length;

    its.forEach((item) {
      final json = jsonDecode(item.body);

      final List<dynamic>? sources = json?['sources'];
      final List<dynamic>? subtitles = json?['subtitles'];

      doneSources++;

      if (sources?.isEmpty == true) return update([], doneSources == totalSources);

      final provider = item.request?.url.queryParameters['server'] ?? '';

      sources?.forEach((i) => update(
            [
              VideoStream(
                quality: i['quality']?.trim() == 'master' ? "multi-quality" : i['quality'],
                url: i['url'],
                server: provider,
                backup: false,
                subtitleFormat: SubtitleFormat.VTT.name, // gojo uses vtt mainly
                customHeaders: headers,
                subtitle: subtitles?.where((it) => it['lang'] == "English").firstOrNull?['url'] ?? //pick only english
                    subtitles?.firstOrNull?['url'],
              )
            ],
            doneSources == totalSources,
          ));
    });
  }

  @override
  Future<void> getDownloadSources(String episodeUrl, Function(List<VideoStream> p1, bool p2) update,
      {bool dub = false, String? metadata}) {
    // download the stream
    throw UnimplementedError();
  }
}
