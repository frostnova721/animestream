import 'dart:convert';

import 'package:animestream/core/anime/providers/animeProvider.dart';
import 'package:animestream/core/anime/providers/types.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart';

class Animegg implements AnimeProvider {
  @override
  String get providerName => "AnimEgg";

  final baseUrl = "https://www.animegg.org";

  @override
  Future<List<Map<String, String?>>> search(String query) async {
    final url = "$baseUrl/search/auto/?q=$query";
    final res = await get(Uri.parse(url));

    final List<Map<String, dynamic>> items = List.castFrom(jsonDecode(res.body));

    final searchResults = <Map<String, String?>>[];

    for (final it in items) {
      final img = (it['thumbnailUrl']?.startsWith("//") ?? false) ? "https:${it['thumbnailUrl']}" : null;
      searchResults.add({
        'name': it['name'],
        'alias': (it['url']?.startsWith("/") ?? false) ? "$baseUrl${it['url']}" : "",
        'imageUrl': img,
      });
    }

    return searchResults;
  }

  @override
  Future<List<Map<String, dynamic>>> getAnimeEpisodeLink(String aliasId, {bool dub = false}) async {
    final url = aliasId;

    final res = await get(Uri.parse(url));

    final html = parse(res.body);

    final tab = html.getElementsByClassName("newmanga").firstOrNull;

    if (tab == null) {
      throw Exception("Couldnt find the episodes section.");
    }

    final List<Map<String, dynamic>> eps = [];

    for (int i = tab.children.length - 1; i >= 0; i--) {
      final elem = tab.children[i];
      final div = elem.children.firstOrNull;
      final a = div?.children.firstOrNull;

      if (div == null || a == null) {
        throw Exception("Couldnt find the element with the episode infos");
      }

      final title = div.getElementsByClassName("anititle").firstOrNull?.text.trim();
      final url = baseUrl + (a.attributes['href'] as String); // this line on hopes n dreams

      eps.add({
        'episodeNumber': tab.children.length - i,
        'episodeLink': url,
        'episodeTitle': title?.replaceAll("[Filler]", ""),
        'hasDub': div.querySelector(".btn-xs.btn-dubbed") != null,
        'isFiller': title?.startsWith("[Filler]") ?? false,
      });
    }

    return eps;
  }

  @override
  Future<void> getStreams(String episodeId, Function(List<VideoStream>, bool) update,
      {bool dub = false, String? metadata}) async {
    final watchPage = await get(Uri.parse(episodeId));

    final html = parse(watchPage.body);

    final videos = html.getElementById("videos");

    if (videos == null) throw Exception("Couldnt find streams!");

    // the elem is a <li>
    for (final elem in videos.children) {
      final listItems = elem.children;

      // the item is <a>
      for (final item in listItems) {
        final isSub = item.attributes['data-version'] == "subbed";

        if (dub != !isSub) {
          continue;
        }

        final id = item.attributes['data-id'];
        if (id == null) continue; // not found
        final streamPageUrl = "$baseUrl/embed/$id";

        final streamRes = await get(Uri.parse(streamPageUrl));
        final streamHtml = parse(streamRes.body);
        final scripts = streamHtml.querySelectorAll('script');

        bool gotScript = false;

        for (final script in scripts) {
          if (gotScript) break;
          final body = script.innerHtml;
          final match = RegExp(r"var\s+videoSources\s*=\s*(\[[\s\S]*?\]);", multiLine: true).firstMatch(body);
          if (match == null) {
            continue;
          } else {
            gotScript = true;
          }
          final raw = match.group(1)!;

          final cleaned = raw.replaceAllMapped(RegExp(r'(\w+):'), (m) => '"${m[1]}":').replaceAll("'", '"');

          final List<Map<String, dynamic>> sourceList = List.castFrom(jsonDecode(cleaned));

          sourceList.forEach((e) {
            update([
              VideoStream(quality: e['label'], url: baseUrl + e['file'], server: "AnimEgg", backup: e['isBk'] ?? false,
              customHeaders: {
                'referer': streamPageUrl,
              }
              )
            ], false);
          });
        }
      }
    }

    update([], true); // too lazy to track the index n stuff, just send finished!
  }

  @override
  Future<void> getDownloadSources(String episodeUrl, Function(List<VideoStream>, bool) update,
      {bool dub = false, String? metadata}) {
    throw UnimplementedError();
  }
}
