import 'dart:convert';

import 'package:animestream/core/anime/providers/animeProvider.dart';
import 'package:animestream/core/anime/providers/types.dart';
import 'package:html/parser.dart' as html;
import 'package:http/http.dart';

class AniDB implements AnimeProvider {
  @override
  final String providerName = "Anidb";

  static const _baseUrl = "https://anidb.app";
  static const Map<String, String> _headers = {
    "User-Agent": "Chrome",
  };

  @override
  Future<List<Map<String, String?>>> search(String query) async {
    final res = await get(
      Uri.parse('$_baseUrl/browse?q=$query'),
      headers: _headers,
    );

    final document = html.parse(res.body);
    final aTags = document.querySelectorAll(".anime-grid a");

    final List<Map<String, String?>> results = [];

    for (final tag in aTags) {
      final id = tag.attributes['href']?.split('/').last;
      final title = tag.querySelector('p')?.text;
      final cover = tag.querySelector('img')?.attributes['src'];

      if (id != null) {
        results.add({
          'name': title,
          'alias': id,
          'imageUrl': cover,
        });
      }
    }

    return results;
  }

  @override
  Future<List<Map<String, dynamic>>> getAnimeEpisodeLink(String aliasId, {bool dub = false}) async {
    final id = aliasId.split('-').last;

    final res = await get(
      Uri.parse('$_baseUrl/api/frontend/anime/$id/episodes'),
      headers: _headers,
    );

    final List<Map<String, dynamic>> episodes = [];
    final json = jsonDecode(res.body);

    if (json['episodes'] == null) {
      return episodes;
    }

    for (final ep in json['episodes'] as List) {
      final epId = ep['id'].toString();
      final number = ep['number'].toString();
      final isFiller = ep['filler'] as bool? ?? false;

      episodes.add({
        'episodeLink': epId,
        'episodeNumber': number,
        'episodeTitle': null,
        'thumbnail': null,
        'hasDub': dub,
        'isFiller': isFiller,
      });
    }

    return episodes;
  }

  @override
  Future<void> getStreams(
    String episodeId,
    Function(List<VideoStream>, bool) update, {
    bool dub = false,
    String? metadata,
  }) async {
    final res = await get(
      Uri.parse('$_baseUrl/api/frontend/episode/$episodeId/languages'),
      headers: _headers,
    );

    final json = jsonDecode(res.body);

    if (json['languages'] == null) {
      update([], true);
      return;
    }

    for (final stream in json['languages'] as List) {
      final embedUrl = stream['embed_url'];
      if (embedUrl == null) continue;

      final resEmbed = await get(Uri.parse(embedUrl), headers: _headers);
      final document = html.parse(resEmbed.body);
      final scriptTags = document.querySelectorAll('body script');

      if (scriptTags.length > 1) {
        final scriptContent = scriptTags[1].text;

        final match = RegExp(
          r"file:\s*'([^']+\.m3u8[^']*)'",
        ).firstMatch(scriptContent);

        if (match != null) {
          final url = match.group(1)!;
          // final isDub = (stream['language'] as String?)?.toLowerCase() == 'english';

          // if(isDub != dub) {
          //   continue; // Skip if the dub preference doesn't match
          // }

          final quality = stream['name']?.toString() ?? 'default';

          update(
            [
              VideoStream(
                url: url,
                quality: quality,
                server: 'Anidb',
                backup: false,
                // customHeaders: _headers,
              )
            ],
            false,
          );
        }
      }
    }

    update([], true);
  }

  @override
  Future<void> getDownloadSources(
    String episodeUrl,
    Function(List<VideoStream>, bool) update, {
    bool dub = false,
    String? metadata,
  }) async {
    throw UnimplementedError();
  }
}
