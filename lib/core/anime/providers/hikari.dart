import 'dart:convert';

import 'package:animestream/core/anime/extractors/streamwish.dart';
import 'package:animestream/core/anime/providers/animeProvider.dart';
import 'package:animestream/core/anime/providers/types.dart';
import 'package:animestream/ui/models/extensions.dart';
import 'package:http/http.dart';

class Hikari extends AnimeProvider {
  @override
  String get providerName => "hikari";

  final apiUrl = "https://api.hikari.gg/api";

  @override
  Future<List<Map<String, String?>>> search(String query) async {
    // basically an anilist search
    final searchApi = "$apiUrl/anime/?sort=created_at&order=asc&page=1&search=$query";
    final response = await get(Uri.parse(searchApi));
    final json = jsonDecode(response.body);
    final List<Map<String, dynamic>> results = (json['results'] as List).cast();
    final List<Map<String, String?>> sr = [];
    for (final item in results) {
      final id = item['uid'];
      final cover = item['ani_poster'];
      final title = item['ani_name'];
      sr.add({'alias': "$id", 'imageUrl': cover, 'name': title});
    }
    return sr;
  }

  @override
  Future<List<Map<String, dynamic>>> getAnimeEpisodeLink(String aliasId, {bool dub = false}) async {
    final infoApi = "$apiUrl/episode/uid/$aliasId";
    final apiRes = await get(Uri.parse(infoApi));
    final List<Map<String, dynamic>> jsoned = (jsonDecode(apiRes.body) as List).cast();
    final eps = <Map<String, dynamic>>[];
    for (int i = 0; i < jsoned.length; i++) {
      final it = jsoned[i];
      final epNum = it['ep_id_name'];
      final title = it['ep_name'];
      eps.add({
        'episodeNumber': int.tryParse(epNum ?? '0'),
        'episodeLink': "$aliasId+$epNum",
        'episodeTitle': title,
      });
    }
    return eps;
  }

  @override
  Future<void> getStreams(String episodeId, Function(List<VideoStream> p1, bool p2) update,
      {bool dub = false, String? metadata}) async {
    final embedApi = "$apiUrl/embed/${episodeId.split('+').join('/')}"; // in $apiurl/$id/epNum form
    final resp = await get(Uri.parse(embedApi));
    final List<Map<String, dynamic>> jsoned = (jsonDecode(resp.body) as List).cast();

    final totalStreams = jsoned.length;
    int streamsPushed = 0;

    final sw = StreamWish();

    for (final stream in jsoned) {
      if ((stream['embed_name'] as String? ?? "").toLowerCase() == "playerx") {
        // cus we dont have its extractor!
        streamsPushed++;
        continue;
      }
      final embedLink = stream['embed_frame'] as String;
      switch (stream['embed_name'].toLowerCase()) {
        case 'sv':
          {
            sw.extract(embedLink,
                label: "SV", headersOverrides: {
                  'Referer': embedLink,
                  'Origin': "https://${embedLink.toUri()!.host}",
                  'Accept': "*/*",
                }).then((val) => update(val, streamsPushed == totalStreams));
            break;
          }
        case 'streamwish':
          sw.extract(embedLink, label: "StreamWish").then((val) => update(val, streamsPushed == totalStreams));
          break;
        // case
      }
    }
  }

  @override
  Future<void> getDownloadSources(String episodeUrl, Function(List<VideoStream> p1, bool p2) update,
      {bool dub = false, String? metadata}) {
    // TODO: implement getDownloadSources
    throw UnimplementedError();
  }
}
