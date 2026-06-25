import 'dart:convert';

import 'package:animestream/core/anime/extractors/type.dart';
import 'package:animestream/core/anime/providers/types.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart';

class VidtubeExtractor implements AnimeExtractor {
  @override
  Future<List<VideoStream>> extract(String streamUrl, {String quality = "multi-quality", String? server}) async {
    final headers = {
      "X-Requested-With": "XMLHttpRequest",
    };

    final uri = Uri.parse(streamUrl);
    final streamSite = await get(uri);

    final doc = parse(streamSite.body);

    final id = doc.getElementById("megaplay-player")?.attributes['data-id'];

    if (id == null) {
      throw Exception("Failed to extract video ID from the video page.");
    }

    final type = uri.pathSegments.last;

    final finalResponse = await get(Uri.parse("https://vidtube.site/stream/getSourcesNew?id=$id&type=$type"), headers: headers);
    final jsonResponse = jsonDecode(finalResponse.body);

    final sources = jsonResponse['sources'];
    final subs = List.castFrom(jsonResponse['tracks']).where((t) => t['kind'] == "captions").toList();

    // expected 1 file from the sources. I think bro intended to name it "source"
    final playlist = sources['file'];

    if (playlist == null || playlist.isEmpty) {
      throw Exception("No video sources found.");
    }

    String? sub = subs.firstWhere((s) => s['lang'].toString() == "english", orElse: () => {})['file'];
    if (sub == null || sub.isEmpty) {
      sub = subs.firstWhere((s) => s['default'], orElse: () => {})['file'];
    }

    final videStream = VideoStream(
      quality: quality,
      url: playlist,
      server: server ?? "vidtube",
      backup: false,
      subtitle: sub,
      subtitleFormat: sub != null ? "vtt" : null, // hopes n dreams
      customHeaders: {
        "Referer": "https://vidtube.site/",
        "Origin": "https://vidtube.site",
      }
    );

    return [videStream];
  }
}
