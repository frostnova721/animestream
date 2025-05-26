import 'dart:convert';

import 'package:animestream/core/anime/providers/animeProvider.dart';
import 'package:animestream/core/anime/providers/types.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/database/anilist/anilist.dart';
import 'package:http/http.dart';

const String apiUrl = "https://backend.gojo.live/api/anime";

final headers = {
  'Origin': 'https://gojo.live',
  'Referer': 'https://gojo.live/',
};

//use anilist for searching
class Gojo extends AnimeProvider {
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
          'img': (img?.isEmpty ?? true) ? null : img,
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
      };
    }).toList();

    return links;
  }

  @override
  Future<void> getStreams(String epLink, Function(List<VideoStream> list, bool isFinished) update,
      {bool dub = false, String? metadata}) async {
    final linkSplit = epLink.split("+");

    final List<Future<Response>> futures = [];

    //only select with even indexes (odd ones have providers)
    final listWithOnlyIds = linkSplit.where((item) => linkSplit.indexOf(item) % 2 == 0).toList();
    int i = 0;
    listWithOnlyIds.forEach((it) {
      final providerIndex = linkSplit.indexOf(it, i) + 1;
      i = providerIndex;
      final url =
          "$apiUrl/tiddies?provider=${linkSplit[providerIndex]}&id=178100&num=${listWithOnlyIds.indexOf(it) + 1}&subType=sub&watchId=$it&dub_id=null";
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

      final provider = item.request?.url.queryParameters['provider'] ?? '';
      doneSources++;

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
  Future<void> getDownloadSources(String episodeUrl, Function(List<VideoStream> p1, bool p2) update, {bool dub = false, String? metadata}) {
    // download the stream
    throw UnimplementedError();
  }
}
