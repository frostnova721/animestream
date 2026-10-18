import 'dart:convert';

import 'package:animestream/core/anime/providers/animeProvider.dart';
import 'package:animestream/core/anime/providers/types.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/network/network.dart';

class ReAnime implements AnimeProvider {
  @override
  final String providerName = "ReAnime";

  static const _baseUrl = "https://reanime.to";
  static const _apiUrl = "$_baseUrl/api/v1";
  static const _flixCloudUrl = "https://flixcloud.cc";

  static const Map<String, String> _headers = {
    "referer": "https://reanime.to/"
  };

  static final _embedAidRegex = RegExp(r'/e/([a-z0-9]+)');
  static final _fileIdRegex = RegExp(r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}');
  static final _jwtRegex = RegExp(r'eyJ[\w-]+\.[\w-]+\.[\w-]+');
  static final _fetchBaseRegex = RegExp(r'https://fetch\d*\.flixcloud\.cc');
  static final _resolutionRegex = RegExp(r'(\d{3,4}p)');
  static final _progressStatusRegex = RegExp(r'"status":\s*"(\w+)"');
  static final _embedSubtitlesRegex = RegExp(r'subtitles:\s*(\[.*?\])\s*,\s*\w+:', dotAll: true);
  static final _subtitleItemRegex = RegExp(
    r'url:\s*"([^"]+)"\s*,\s*language:\s*"([^"]+)"\s*,\s*format:\s*"([^"]+)"(?:,\s*default:\s*(true|false))?',
  );

  @override
  Future<List<Map<String, String?>>> search(String query) async {
    final res = await get(
      Uri.parse('$_apiUrl/search?limit=10&typeahead=1&q=$query'),
      headers: _headers,
      cacheDuration: const Duration(minutes: 5),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("Request failed. status: ${res.statusCode}");
    }

    final List<Map<String, dynamic>> searchResults = List.castFrom(jsonDecode(res.body)['results']);

    final results = <Map<String, String>>[];

    for (final item in searchResults) {
      final String? title = item['title']?['english'] ?? item['title']?['romaji'] ?? item['title']?['native'];
      final String? cover = item['cover_image']?['large'] ?? item['cover_image']?['extra_large'];
      final String? id = item['anime_id'];

      if (title != null && cover != null && id != null) {
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
    String anilistId = '';
    try {
      final detailRes = await get(
        Uri.parse('$_apiUrl/anime/$aliasId'),
        headers: _headers,
        cacheDuration: const Duration(hours: 24),
      );
      if (detailRes.statusCode >= 200 && detailRes.statusCode < 300) {
        final detailJson = jsonDecode(detailRes.body);
        anilistId = (detailJson['anilist_id'] ?? '').toString();
      }
    } catch (_) {}

    final res = await get(
      Uri.parse('$_apiUrl/anime/$aliasId/episodes?limit=2000'),
      headers: _headers,
      cacheDuration: const Duration(minutes: 10),
    );

    final List<Map<String, dynamic>> episodes = [];
    final json = jsonDecode(res.body);

    if (json['data'] == null) {
      return episodes;
    }

    for (final ep in json['data'] as List) {
      final epId = ep['episodeId'].toString();
      final number = ep['episode_number'].toString();
      final isFiller = ep['is_filler'] as bool? ?? false;
      final isDub = ep['dubbed'] as bool? ?? false;
      final thumbnail = ep['thumbnail'] as String?;
      final title = ep['title'] as String?;

      if (dub && !isDub) continue;

      episodes.add({
        'episodeLink': epId,
        'episodeNumber': number,
        'episodeTitle': title,
        'thumbnail': (thumbnail?.isEmpty ?? true) ? null : thumbnail,
        'hasDub': isDub,
        'isFiller': isFiller,
        'metadata': anilistId.isNotEmpty ? "$aliasId|$number|$anilistId" : "$aliasId|$number",
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
    final parts = metadata?.split("|") ?? [];
    final animeId = parts.isNotEmpty ? parts[0] : episodeId;
    final episodeNum = parts.length > 1 ? parts[1] : '1';
    String? anilistId = parts.length > 2 && parts[2].isNotEmpty ? parts[2] : null;

    if (anilistId == null || anilistId.isEmpty) {
      if (int.tryParse(animeId) != null) {
        anilistId = animeId;
      } else {
        try {
          final detailRes = await get(
            Uri.parse('$_apiUrl/anime/$animeId'),
            headers: _headers,
            cacheDuration: const Duration(hours: 24),
          );
          if (detailRes.statusCode >= 200 && detailRes.statusCode < 300) {
            final detailJson = jsonDecode(detailRes.body);
            anilistId = (detailJson['anilist_id'] ?? '').toString();
          }
        } catch (_) {}
      }
    }

    if (anilistId == null || anilistId.isEmpty) {
      update([], true);
      return;
    }

    final flixHeaders = {
      'Accept': 'application/json, text/plain, */*',
      'Referer': '$_baseUrl/watch/$animeId?ep=$episodeNum',
      'Origin': _baseUrl,
    };

    final res = await get(
      Uri.parse('$_baseUrl/api/flix/$anilistId/$episodeNum'),
      headers: flixHeaders,
      cacheDuration: const Duration(hours: 1),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      update([], true);
      return;
    }

    final json = jsonDecode(res.body);
    if (json['servers'] == null || json['servers'] is! List) {
      update([], true);
      return;
    }

    final List servers = json['servers'];

    final dubServers = servers.where((s) => (s['dataType'] as String?)?.toLowerCase() == 'dub').toList();
    final subServers = servers.where((s) => (s['dataType'] as String?)?.toLowerCase() != 'dub').toList();

    // Filter strictly by the requested dub preference
    final targetServers = dub ? dubServers : subServers;

    if (targetServers.isEmpty) {
      update([], true);
      return;
    }

    for (final server in targetServers) {
      final String? dataLink = server['dataLink'];
      if (dataLink == null || dataLink.isEmpty) continue;

      final serverName = server['serverName']?.toString() ?? 'Default';
      final isServerDub = (server['dataType'] as String?)?.toLowerCase() == 'dub';
      // final audioTag = isServerDub ? '[Dub]' : '[Sub]';
      // final softsubTag = (server['softsub'] == true) ? ' [Softsub]' : '';
      final label = '$serverName';

      try {
        final ddlStream = await _extractDdl(dataLink, label, isDub: isServerDub);
        if (ddlStream != null) {
          update([ddlStream], false);
        }
      } catch (_) {}
    }

    update([], true);
  }

  Future<VideoStream?> _extractDdl(String dataLink, String label, {bool isDub = false}) async {
    final aidMatch = _embedAidRegex.firstMatch(dataLink);
    if (aidMatch == null) return null;
    final aid = aidMatch.group(1)!;

    final dlHeaders = {
      'Accept': '*/*',
      'Origin': _flixCloudUrl,
      'Referer': '$_flixCloudUrl/',
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36',
    };

    // Fetch embed page (for English subtitles) and __data.json (for MKV token) concurrently
    final responses = await Future.wait([
      get(
        Uri.parse('$_flixCloudUrl/d/$aid/__data.json'),
        headers: dlHeaders,
        cacheDuration: const Duration(hours: 1),
      ),
      get(
        Uri.parse(dataLink),
        headers: dlHeaders,
        cacheDuration: const Duration(hours: 1),
      ),
    ]);

    final metaRes = responses[0];
    final embedRes = responses[1];

    if (metaRes.statusCode < 200 || metaRes.statusCode >= 300) return null;

    final dataBody = metaRes.body;
    final fileId = _fileIdRegex.firstMatch(dataBody)?.group(0);
    final token = _jwtRegex.firstMatch(dataBody)?.group(0);
    final base = _fetchBaseRegex.firstMatch(dataBody)?.group(0) ?? _flixCloudUrl;
    final resolution = _resolutionRegex.firstMatch(dataBody)?.group(1);

    if (fileId == null || token == null) return null;

    // Extract English subtitle from embed page
    String? subtitleUrl;
    String? subtitleFormat;
    if (embedRes.statusCode >= 200 && embedRes.statusCode < 300) {
      final sub = _pickBestEnglishSub(embedRes.body, isDub: isDub);
      if (sub != null) {
        subtitleUrl = sub.$1;
        subtitleFormat = sub.$2;
      }
    }

    bool ready = false;
    for (int i = 0; i < 3; i++) {
      try {
        final progRes = await get(
          Uri.parse('$base/download/$fileId/progress?token=$token'),
          headers: dlHeaders,
        );
        if (progRes.statusCode == 200) {
          final status = _progressStatusRegex.firstMatch(progRes.body)?.group(1);
          if (status == 'ready') {
            ready = true;
            break;
          }
        }
      } catch (_) {}
      if (!ready) await Future.delayed(const Duration(milliseconds: 500));
    }

    if (!ready) return null;

    final downloadUrl = '$base/download/$fileId?token=$token';
    final qualityStr = resolution ?? '1080p';

    return VideoStream(
      quality: qualityStr,
      url: downloadUrl,
      server: '$label [MKV]',
      backup: false,
      subtitle: subtitleUrl,
      subtitleFormat: subtitleFormat,
      dub: isDub,
      customHeaders: {
        'Origin': _flixCloudUrl,
        'Referer': '$_flixCloudUrl/',
      },
    );
  }

  (String, String)? _pickBestEnglishSub(String html, {bool isDub = false}) {
    final subBlockMatch = _embedSubtitlesRegex.firstMatch(html);
    if (subBlockMatch == null) return null;

    final block = subBlockMatch.group(1)!;
    final matches = _subtitleItemRegex.allMatches(block);

    final engSubs = <({String url, String lang, String fmt, bool isDefault})>[];
    for (final m in matches) {
      final url = m.group(1)!;
      final lang = m.group(2)!;
      final fmt = m.group(3)!;
      final isDef = m.group(4) == 'true';
      if (lang.toLowerCase().contains('english')) {
        engSubs.add((url: url, lang: lang, fmt: fmt, isDefault: isDef));
      }
    }

    if (engSubs.isEmpty) return null;

    if (isDub) {
      // For Dub: Prefer Signs & Songs or Forced subtitles so spoken English dialogue is not duplicated
      for (final s in engSubs) {
        final l = s.lang.toLowerCase();
        if (l.contains('sign') || l.contains('song') || l.contains('forced')) {
          return (s.url, _normalizeFormat(s.fmt));
        }
      }

      // Secondary for Dub: Dubtitle
      for (final s in engSubs) {
        final l = s.lang.toLowerCase();
        if (l.contains('dubtitle')) {
          return (s.url, _normalizeFormat(s.fmt));
        }
      }

      // If neither is present, do not force dialogue subtitles over English audio
      return null;
    } else {
      // For Sub: Prefer Dialogue or Full subtitles (excluding AI dubtitle)
      for (final s in engSubs) {
        final l = s.lang.toLowerCase();
        if ((l.contains('dialog') || l.contains('full')) && !l.contains('dubtitle')) {
          return (s.url, _normalizeFormat(s.fmt));
        }
      }

      // Default flagged subtitle (excluding dubtitle)
      for (final s in engSubs) {
        if (s.isDefault && !s.lang.toLowerCase().contains('dubtitle')) {
          return (s.url, _normalizeFormat(s.fmt));
        }
      }

      // Fallback to first non-dubtitle or first available English sub
      final chosen = engSubs.firstWhere(
        (s) => !s.lang.toLowerCase().contains('dubtitle'),
        orElse: () => engSubs.first,
      );
      return (chosen.url, _normalizeFormat(chosen.fmt));
    }
  }

  String _normalizeFormat(String fmt) {
    final upper = fmt.toUpperCase();
    if (upper == 'ASS') return SubtitleFormat.ASS.name;
    if (upper == 'SRT') return SubtitleFormat.SRT.name;
    return SubtitleFormat.VTT.name;
  }

  @override
  Future<void> getDownloadSources(
    String episodeUrl,
    Function(List<VideoStream>, bool) update, {
    bool dub = false,
    String? metadata,
  }) async {
    return getStreams(episodeUrl, update, dub: dub, metadata: metadata);
  }
}
