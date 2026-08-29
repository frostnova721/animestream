import 'dart:convert';

import 'package:animestream/core/anime/extractors/vidtube.dart';
import 'package:animestream/core/anime/providers/animeProvider.dart';
import 'package:animestream/core/anime/providers/types.dart';
import 'package:animestream/core/app/logging.dart';
import 'package:html/parser.dart';
import 'package:animestream/core/network/network.dart';

class Anikoto implements AnimeProvider {
  @override
  final String providerName = "Anikoto";

  //final _baseUrl = "https://anikototv.to";
  final _ajaxUrl = "https://anikototv.to/ajax";
  final _mapperUrl = "https://mapper.nekostream.site/";

  final _headers = {
    "Referer": "https://anikototv.to/",
    "X-Requested-With": "XMLHttpRequest",
  };

  @override
  Future<List<Map<String, String?>>> search(String query) async {
    final url = "$_ajaxUrl/anime/search?keyword=$query";
    final sr = <Map<String, String?>>[];
    final res = await get(
      Uri.parse(url),
      headers: _headers,
      cacheDuration: const Duration(minutes: 5),
    );

    final json = jsonDecode(res.body);
    final htmlString = json['result']?['html'];

    if (htmlString == null) {
      throw Exception("Failed to fetch search results");
    }

    final html = parse(htmlString);

    final items = html.querySelector("div.scaff.items")?.children;

    if (items == null) {
      throw Exception("Failed to parse search results. No items found.");
    }

    for (final item in items) {
      final title = item.querySelector(".name.d-title")?.text.trim();
      final link = item.attributes['href'];
      final img = item.querySelector("img")?.attributes['src'];

      if (title != null && link != null) {
        sr.add({
          'name': title,
          'alias': link,
          'imageUrl': img,
        });
      }
    }

    return sr;
  }

  @override
  Future<List<Map<String, dynamic>>> getAnimeEpisodeLink(String aliasId, {bool dub = false}) async {
    final url = Uri.parse(aliasId);

    final webRes = await get(
      url,
      headers: _headers,
      cacheDuration: const Duration(minutes: 5),
    );

    final html = parse(webRes.body);
    final id = html.querySelector("div#watch-main")?.attributes['data-id']?.trim();

    if (id == null) {
      throw Exception("Failed to fetch anime episode link. No data-id found.");
    }

    final episodeListUrl = "$_ajaxUrl/episode/list/$id?vrf=";

    final episodeListRes = await get(
      Uri.parse(episodeListUrl),
      headers: _headers,
      cacheDuration: const Duration(minutes: 5),
    );

    final episodeListJson = jsonDecode(episodeListRes.body);
    final episodeListHtml = episodeListJson['result'];

    if (episodeListHtml == null) {
      throw Exception("Failed to fetch episode list. No HTML found.");
    }

    final episodeListDoc = parse(episodeListHtml);
    final episodeItems = episodeListDoc.querySelector("div.episodes")?.children;

    if (episodeItems == null) {
      throw Exception("Failed to parse episode list. No episodes found.");
    }

    final episodes = <Map<String, dynamic>>[];

    // atp its a list of ul, with each of max 100 entries
    for (final range in episodeItems) {
      for (final episode in range.children) {
        final title = episode.attributes['title']?.trim();
        final a = episode.querySelector("a");

        if (a == null) {
          continue;
        }

        final episodeId = a.attributes['data-ids']?.trim();
        final episodeLink = a.attributes['href'];
        final dataMal = a.attributes['data-mal']?.trim();
        final episodeNumber = a.attributes['data-num']?.trim();
        final dubAvailable = a.attributes['data-dub']?.trim() == '1';
        final isFiller = a.className.trim().contains('filler');

        if (episodeLink != null && episodeNumber != null) {
          episodes.add({
            'episodeLink': episodeId,
            'episodeNumber': episodeNumber,
            'episodeTitle': title,
            'thumbnail': null,
            'hasDub': dubAvailable,
            'isFiller': isFiller,
            'metadata': "$dataMal-$episodeNumber",
          });
        }
      }
    }

    return episodes;
  }

  @override
  Future<void> getStreams(String episodeId, Function(List<VideoStream>, bool) update,
      {bool dub = false, String? metadata}) async {
    // do this mf async-ly it should be giving a response till we got the other streams
    Future<Map<String, dynamic>>? kiwires;
    final splitMetadata = metadata?.split("-");
    if (splitMetadata != null && splitMetadata.length == 2) {
      final ep = int.tryParse(splitMetadata[1]) ?? 0;
      if (ep > 0) {
        kiwires = _getKiwiStreamId(splitMetadata[0], ep);
      }
    }

    final serverListUrl = "$_ajaxUrl/server/list?servers=$episodeId";

    final serverListRes = await get(
      Uri.parse(serverListUrl),
      headers: _headers,
      cacheDuration: const Duration(hours: 1),
    );

    final serverListJson = jsonDecode(serverListRes.body);
    final serverListHtml = serverListJson['result'];

    if (serverListHtml == null) {
      throw Exception("Failed to fetch server list. No HTML found.");
    }

    final serverListDoc = parse(serverListHtml);
    final groups = serverListDoc.querySelectorAll("div.servers");

    final servers = <Map<String, String?>>[];

    for (final group in groups) {
      final grpName = group.firstChild?.text?.trim();
      final items = group.querySelector("ul")?.children;

      if (items == null) {
        continue;
      }

      for (final item in items) {
        final serverName = item.text.trim();
        final linkId = item.attributes['data-link-id']?.trim();

        final isDub = grpName?.toLowerCase().contains("dub") ?? false;

        if (isDub != dub) {
          continue;
        }

        servers.add({"srv_name": serverName, "link_id": linkId, "group_name": grpName});
      }

      // it should be recieving the kiwires data in parallel, so we can update the streams as soon as we get them
      final kiwiresData = await kiwires;
      if (kiwiresData != null && kiwiresData.isNotEmpty) {
        servers.add({"srv_name": "Kiwi", "link_id": kiwiresData['sub']?['url']?.toString(), "group_name": "Kiwi"});
      }
    }

    final serverGetUrl = "$_ajaxUrl/server?get=";

    for (final server in servers) {
      final linkId = server['link_id'];
      if (linkId == null) {
        continue;
      }

      final serverRes = await get(
        Uri.parse("$serverGetUrl$linkId"),
        headers: _headers,
        cacheDuration: const Duration(hours: 1),
      );

      final serverJson = jsonDecode(serverRes.body);

      final streamUrl = serverJson['result']?['url']?.trim();

      if (streamUrl == null) {
        continue;
      }

      update(await _extractStreams(streamUrl, server: server['srv_name']), false);
    }

    update([], true);
  }

  Future<List<VideoStream>> _extractStreams(String streamUrl,
      {String quality = "multi-quality", String? server}) async {
    final host = Uri.parse(streamUrl).host.toLowerCase().split(".").first;

    switch (host.toLowerCase()) {
      case "vidtube":
        return await VidtubeExtractor().extract(streamUrl, quality: quality, server: server);
      case "megaplay":
        return await _extractMegaPlayStream(streamUrl, quality, server);
      // case "mewcdn":
      //   return Kwik().extract(streamUrl, quality: quality, server: server);
      default:
        {
          Logs.app.log("Couldnt find extractor for $host");
          return [];
        }
    }
  }

  Future<List<VideoStream>> _extractMegaPlayStream(String url, String quality, String? server) async {
    final getSourcesUrl = "https://megaplay.buzz/stream/getSources?id=";
    final res = await get(
      Uri.parse(url),
      headers: _headers,
      cacheDuration: Duration(minutes: 30),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      return [];
    }

    final html = parse(res.body);
    final playerDiv = html.querySelector("#megaplay-player");

    if (playerDiv == null) {
      Logs.app.log("[Megaplay] Couldnt find player div");
      return [];
    }

    final mediaId = playerDiv.attributes['data-id'];

    if (mediaId == null) {
      Logs.app.log("[Megaplay] Couldnt find data-id");
      return [];
    }

    final sourcesRes = await get(Uri.parse("$getSourcesUrl$mediaId"),
        headers: {'X-Requested-With': "XMLHttpRequest", 'Referer': "https://megaplay.buzz/"},
        cacheDuration: Duration(minutes: 30));

    final sourcesJson = jsonDecode(sourcesRes.body);

    final String? streamUrl = sourcesJson['sources']?['file'];

    if (streamUrl == null) {
      Logs.app.log("[Megaplay] No source file found from /getSources.");
      return [];
    }

    final List<Map<String, dynamic>> subs = List.castFrom(sourcesJson['tracks'] ?? []);

    final engSub = subs.firstWhere(
      (it) => it['kind'] == "captions" && (it['label'] ?? "").toLowerCase() == "english",
      orElse: () {
        return subs.firstWhere((ite) => ite['kind'] == "captions" && ite['default'] == true, orElse: () => {});
      },
    );

    if (engSub.isEmpty) {
      print("No subs available");
    }

    final cleanedSubLink = (engSub['file'] as String?)?.replaceAll(r"\", "");

    const formats = {'srt', 'vtt', 'ass'};

    final uri = Uri.tryParse(cleanedSubLink ?? '');
    final fileName = uri?.pathSegments.last;
    final ext = fileName?.split('.').last.toLowerCase();

    final subtitleFormat = formats.contains(ext) ? ext : null;

    return [
      VideoStream(
        quality: quality,
        url: streamUrl.replaceAll(r"\", ""),
        server: server ?? "Megaplay",
        backup: false,
        customHeaders: {
          'Referer': 'https://megaplay.buzz/',
        },
        subtitle: cleanedSubLink,
        subtitleFormat: subtitleFormat ?? "vtt",
      )
    ];
  }

  Future<Map<String, dynamic>> _getKiwiStreamId(String malId, int ep) async {
    final mapperApiUrl = "$_mapperUrl/api/mal/$malId/$ep/${DateTime.now().millisecondsSinceEpoch ~/ 1000}";

    // remove the XMLHTTPRequest header if causing issues
    final mapperRes = await get(
      Uri.parse(mapperApiUrl),
      headers: _headers,
      cacheDuration: const Duration(hours: 1),
    );

    final mapperJson = jsonDecode(mapperRes.body);

    return Map.castFrom(mapperJson['Kiwi-Stream-'] ?? {});
  }

  @override
  Future<void> getDownloadSources(String episodeUrl, Function(List<VideoStream>, bool) update,
      {bool dub = false, String? metadata}) async {
    throw UnimplementedError();
  }
}
