import 'package:animestream/core/anime/providers/animeProvider.dart';
import 'package:animestream/core/anime/providers/types.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart';

class AniZone extends AnimeProvider {
  final baseUrl = "https://anizone.to";

  @override
  Future<List<Map<String, String?>>> search(String query) async {
    final url = "$baseUrl/anime?search=$query";
    final res = await get(Uri.parse(url));

    final doc = parse(res.body);
    final grid = doc.querySelector("div.grid.grid-cols-1.gap-4");
    if (grid == null) {
      throw Exception("Got list of children as null.");
    }
    final children = grid.children;

    final List<Map<String, String?>> searchRes = [];

    for (final child in children) {
      final a = child.querySelector("a");
      if (a == null) {
        throw Exception("Found null item.");
      }
      final title = a.attributes['title'];
      final href = a.attributes['href'];

      final img = child.querySelector("img")?.attributes['src'];
      if (img == null || href == null || title == null) {
        throw Exception("Found null image/title/url.");
      }

      searchRes.add({
        'name': title,
        'alias': href,
        'imageUrl': img,
      });
    }

    return searchRes;
  }

  @override
  Future<List<Map<String, dynamic>>> getAnimeEpisodeLink(String aliasId, {bool dub = false}) async {
    print(aliasId);
    final url = aliasId;
    final res = await get(Uri.parse(url));
    final doc = parse(res.body);

    final list = doc.querySelector("ul.grid.grid-cols-1")?.children;

    final epList = <Map<String, dynamic>>[];

    if (list == null) return [];

    int i = 1;

    for (final item in list) {
      final epLink = item.querySelector("a")?.attributes['href'];
      final epImg = item.querySelector("img")?.attributes['src'];
      final title = item.querySelector("h3")?.text;
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
    final res = await get(Uri.parse(url));
    final doc = parse(res.body);

    final mediaPlayer = doc.querySelector("media-player");
    if (mediaPlayer == null) {
      throw Exception("Couldnt find media player");
    }

    final src = mediaPlayer.attributes['src'];

    if (src == null) {
      throw Exception("Failed to resolve the source link");
    }

    final tracks = mediaPlayer.querySelectorAll("track");

    final List<Map<String, String>> subs = [];

    for (final track in tracks) {
      if (track.attributes['srclang'] == "en" && track.attributes['kind'] == "subtitles" && track.attributes.containsKey("default")) {
        subs.add({'url': track.attributes['src']!, 'type': track.attributes['data-type']!});
      }
    }

    final srcName =
        doc.querySelector(".flex.gap-2.relative.items-center.p-3.rounded-lg.text-white.bg-teal-600")?.text.trim() ??
            "single";

    update([
      VideoStream(
          quality: "multi-quality",
          link: src,
          server: srcName,
          subtitle: subs.first['url'],
          subtitleFormat: subs.first['type'],
          backup: false)
    ], true);
  }

  @override
  String get providerName => "anizone";
}
