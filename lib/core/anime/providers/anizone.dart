import 'dart:convert';

import 'package:animestream/core/anime/providers/animeProvider.dart';
import 'package:animestream/core/anime/providers/types.dart';
import 'package:html/parser.dart';
import 'package:animestream/core/network/network.dart';

class AniZone extends AnimeProvider {
  final baseUrl = "https://anizone.to";

  @override
  Future<List<Map<String, String?>>> search(String query) async {
    final url = "$baseUrl/anime?search=$query";
    final res = await get(
      Uri.parse(url),
      cacheDuration: const Duration(minutes: 5),
    );

    final doc = parse(res.body);
    // final grid = doc.querySelector("ul.grid.grid-cols-1.gap-4");
    // if (grid == null) {
    //   throw Exception("Got list of children as null.");
    // }
    // final children = grid.querySelectorAll("li");

    final data = doc.querySelector("main")?.children[1];

    final divData = data?.attributes['x-data'];

    final matchRegEx = RegExp(r"JSON\.parse\('(.+?)'\)", dotAll: true);

    final match = matchRegEx.firstMatch(divData ?? "");

    if (match == null) {
      throw Exception("Couldn't find anime data");
    }

    final parsedJson = List.castFrom(jsonDecode(match.group(1)!.replaceAll(r'\u0022', '"')));

    final List<Map<String, String?>> searchRes = [];

    for (final item in parsedJson) {
      final title = item['main_title'];
      final img = item['cover'];
      final href = item['url'];
      if (img == null || href == null || title == null) {
        throw Exception("Found null image/title/url.");
      }

      searchRes.add({
        'name': title,
        'alias': href.replaceAll("\\", ""),
        'imageUrl': img,
      });
    }

    return searchRes;
  }

  @override
  Future<List<Map<String, dynamic>>> getAnimeEpisodeLink(String aliasId, {bool dub = false}) async {
    final url = aliasId;
    final res = await get(
      Uri.parse(url),
      cacheDuration: const Duration(minutes: 5),
    );
    final doc = parse(res.body);

    final list = doc.querySelector("ul.grid.grid-cols-1")?.children;

    final epList = <Map<String, dynamic>>[];

    if (list == null) return [];

    int i = 1;

    for (final item in list) {
      final divData = item.attributes['x-data'];

      final matchRegEx = RegExp(r"JSON\.parse\('(.+?)'\)", dotAll: true);

      final match = matchRegEx.firstMatch(divData ?? "");

      if (match == null) {
        throw Exception("Couldn't find anime data");
      }

      final title = jsonDecode(match.group(1)!.replaceAll(r'\u0022', '"'))['1'];

      final epLink = item.querySelector("a")?.attributes['href'];
      final epImg = item.querySelector("img")?.attributes['src'];
      // final title = item.querySelector("h3")?.text;
      epList.add({
        'episodeLink': epLink,
        'episodeNumber': i,
        'thumbnail': epImg,
        'episodeTitle': title,
        'isFiller': false,
        'hasDub': false,
      });

      i++;
    }

    return epList;
  }

  @override
  Future<void> getDownloadSources(String episodeUrl, Function(List<VideoStream> p1, bool p2) update,
      {bool dub = false, String? metadata}) {
    throw UnimplementedError();
  }

  @override
  Future<void> getStreams(String episodeId, Function(List<VideoStream> p1, bool p2) update,
      {bool dub = false, String? metadata}) async {
    final url = episodeId;
    final res = await get(
      Uri.parse(url),
      cacheDuration: const Duration(hours: 1),
    );
    final doc = parse(res.body);

    final dataDiv = doc.querySelector("div.mb-8")?.children[0];
    final datas = dataDiv?.attributes['x-data'];

    if (datas == null) {
      throw Exception("Couldnt find data for the stream");
    }

    final matchRegEx = RegExp(r"JSON\.parse\('(.+?)'\)", dotAll: true);

    final match = matchRegEx.firstMatch(datas);

    if (match == null || match.group(1) == null) {
      throw Exception("Couldn't find anime data");
    }

    final streamData = jsonDecode(match.group(1)!.replaceAll(r"\u0022", '"'));

    final src = streamData['src']?.replaceAll("\\", "");
    final subs = List.castFrom(streamData['subtitles']).where((it) => it['language'] == 'en');

    final srcName = doc.querySelector("button.flex.gap-2.relative")?.text.trim() ?? "Default";

    update([
      VideoStream(
          quality: "multi-quality",
          url: src,
          server: srcName,
          subtitle: subs.first['file']?.replaceAll("\\", ""),
          subtitleFormat: subs.first['type'],
          backup: false)
    ], true);
  }

  @override
  String get providerName => "anizone";
}
