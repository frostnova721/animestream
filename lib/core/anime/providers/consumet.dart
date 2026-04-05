import 'dart:convert';
import 'package:animestream/core/anime/providers/animeProvider.dart';
import 'package:animestream/core/anime/providers/types.dart';
import 'package:http/http.dart' as http;

class Consumet extends AnimeProvider {
  @override
  String providerName = "consumet";

  final String baseUrl = "https://api.consumet.org/anime/gogoanime";

  /// SEARCH
  @override
  Future<List<Map<String, String?>>> search(String query) async {
    final res = await http.get(Uri.parse("$baseUrl/$query"));
    final data = jsonDecode(res.body);

    final List results = data["results"] ?? [];

    return results.map<Map<String, String?>>((e) {
      return {
        'name': e['title'],
        'alias': e['id'],
        'imageUrl': e['image'],
      };
    }).toList();
  }

  /// EPISODES
  @override
  Future<List<Map<String, dynamic>>> getAnimeEpisodeLink(String id, {bool dub = false}) async {
    final res = await http.get(Uri.parse("$baseUrl/info/$id"));
    final data = jsonDecode(res.body);

    final List episodes = data["episodes"] ?? [];

    return episodes.map<Map<String, dynamic>>((e) {
      return {
        'episodeLink': e['id'],
        'episodeNumber': e['number'],
        'thumbnail': null,
        'episodeTitle': null,
        'isFiller': false,
        'hasDub': false,
      };
    }).toList();
  }

  /// STREAMS (MAIN PART)
  @override
  Future<void> getStreams(
    String episodeId,
    Function(List<VideoStream>, bool) update, {
    bool dub = false,
    String? metadata,
  }) async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/watch/$episodeId"));
      final data = jsonDecode(res.body);

      final List sources = data["sources"] ?? [];

      List<VideoStream> streams = sources.map<VideoStream>((e) {
        return VideoStream(
          quality: e['quality'] ?? "unknown",
          server: "Consumet",
          url: e['url'],
          customHeaders: {},
          backup: false,
          subtitle: null,
          subtitleFormat: null,
        );
      }).toList();

      update(streams, true);
    } catch (e) {
      print("Consumet error: $e");
      update([], true);
    }
  }

  /// DOWNLOADS (disabled safely)
  @override
  Future<void> getDownloadSources(
    String episodeUrl,
    Function(List<VideoStream>, bool) update, {
    bool dub = false,
    String? metadata,
  }) async {
    update([], true);
  }
}
