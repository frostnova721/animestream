import 'dart:convert';
import 'package:animestream/core/anime/providers/animeProvider.dart';
import 'package:animestream/core/anime/providers/types.dart';
import 'package:http/http.dart' as http;

class Consumet extends AnimeProvider {
  @override
  String providerName = "consumet";

  final baseUrl = "https://api.consumet.org/anime/gogoanime";

  @override
  Future<List<Map<String, String?>>> search(String query) async {
    final res = await http.get(Uri.parse("$baseUrl/$query"));
    final data = jsonDecode(res.body);

    final List results = data["results"] ?? [];

    return results.map<Map<String, String?>>((e) {
      return {
        "name": e["title"],
        "alias": e["id"], // important
        "imageUrl": e["image"],
      };
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getAnimeEpisodeLink(String id, {bool dub = false}) async {
    final res = await http.get(Uri.parse("$baseUrl/info/$id"));
    final data = jsonDecode(res.body);

    final List episodes = data["episodes"] ?? [];

    return episodes.map<Map<String, dynamic>>((e) {
      return {
        "episodeLink": e["id"], // pass directly
        "episodeNumber": e["number"],
        "thumbnail": null,
        "episodeTitle": null,
        "isFiller": false,
        "hasDub": false,
      };
    }).toList();
  }

  @override
  Future<void> getStreams(
    String episodeId,
    Function(List<VideoStream> list, bool) update,
    {bool dub = false, String? metadata}
  ) async {
    final res = await http.get(Uri.parse("$baseUrl/watch/$episodeId"));
    final data = jsonDecode(res.body);

    final List sources = data["sources"] ?? [];

    final streams = sources.map<VideoStream>((s) {
      return VideoStream(
        url: s["url"],
        quality: s["quality"] ?? "auto",
        server: "Consumet",
        backup: false,
        subtitle: null,
        subtitleFormat: null,
      );
    }).toList();

    update(streams, true);
  }
}
