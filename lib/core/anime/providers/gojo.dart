import 'dart:convert';

import 'package:animestream/core/anime/providers/animeProvider.dart';
import 'package:animestream/core/anime/providers/types.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/database/anilist/anilist.dart';
import 'package:http/http.dart';

//use anilist for searching
class Gojo extends AnimeProvider {
  static const String apiUrl = "https://backend.gojo.live/api/anime";

  final baseUrl = "https://gojo.live";

  final headers = {
    'Origin': 'https://gojo.live',
    'Referer': 'https://gojo.live/',
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

    final url = Uri.parse("$apiUrl/episodes/$aliasId");
    final res = await get(url, headers: headers);
    final List<dynamic> json = jsonDecode(res.body);
    final List<Map<String, dynamic>> mapList = [];
    json.forEach((it) {
      final String provider = it['providerId'];

      final List<dynamic> episodeList = it['episodes'];

      final bool hasDub = it['hasDub'];

      final newSht = episodeList.map<Map<String, dynamic>>((item) {
        final int epNum = item['number'];
        final String id = "${item['id']}";
        final bool isFiller = item['isFiller'];
        final String? img = item['image'];
        final String? title = item['title'];

        return {
          'num': epNum,
          'id': id,
          'provider': provider,
          'filler': isFiller,
          'img': (img?.isEmpty ?? true) ? null : img?.replaceAll("https://img.gojo.live/", ""),
          'title': (title?.isEmpty ?? true) ? null : title,
          'hasDub': hasDub
        };
      }).toList();

      mapList.addAll(newSht);
    });

    final Map<int, List<String>> grp = {};

    for (int i = 0; i < mapList.length; i++) {
      final it = mapList[i];
      if (!grp.containsKey(it['num'])) {
        grp[it['num']] = [];
      }
      grp[it['num']]?.add("${it['id']}+${it['provider']}");
    }

    final links = grp.entries.map((ent) {
      final match = mapList.firstWhere(
        (e) => e['num'] == ent.key,
        orElse: () => {},
      );
      return {
        'episodeLink': ent.value.join("+"),
        'episodeNumber': ent.key,
        'filler': match['filler'],
        'thumbnail': match['img'],
        'episodeTitle': match['title'],
        'hasDub': match['hasDub'],
        'metadata': "$aliasId+${ent.key}"
      };
    }).toList();

    return links;
  }

  @override
  Future<void> getStreams(String epLink, Function(List<VideoStream> list, bool isFinished) update,
      {bool dub = false, String? metadata}) async {
    final linkSplit = epLink.split("+");
    if(metadata == null) throw Exception("Couldnt get streams, required field metadata recieved null.");

    final mdsplit = metadata.split("+");

    if(mdsplit.length < 2) throw Exception("id or episodeNumber missing!");

    final id = mdsplit.first;
    final epNum = mdsplit[1];

    final List<Future<Response>> futures = [];

    //only select with even indexes (odd ones have providers)
    final listWithOnlyIds = linkSplit.where((item) => linkSplit.indexOf(item) % 2 == 0).toList();
    int i = 0;
    listWithOnlyIds.forEach((it) {
      final providerIndex = linkSplit.indexOf(it, i) + 1;
      i = providerIndex;
      final url =
          "$apiUrl/tiddies?provider=${linkSplit[providerIndex]}&id=$id&num=$epNum&subType=${dub ? "dub" : "sub"}&watchId=$it&dub_id=null";
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

      if(sources?.isEmpty == true) return update([], doneSources == totalSources);

      final provider = item.request?.url.queryParameters['provider'] ?? '';

      sources?.forEach((i) => update(
            [
              VideoStream(
                quality: i['quality']?.trim() == 'master' ? "multi-quality" : i['quality'],
                link: i['url'],
                isM3u8: i['url'].endsWith('.m3u8'),
                server: provider,
                backup: false,
                subtitleFormat: SubtitleFormat.VTT.name,
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
