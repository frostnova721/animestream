import 'dart:convert';

import 'package:animestream/core/anime/providers/animeProvider.dart';
import 'package:animestream/core/anime/providers/types.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/database/anilist/anilist.dart';
import 'package:http/http.dart';

class AniPlay extends AnimeProvider {
  final String providerName = "aniplay";

  static const baseUrl = "https://aniplaynow.live";

  @override
  Future<List<Map<String, dynamic>>> getAnimeEpisodeLink(String aliasId, {bool dub = false}) async {
    final serversAndEps = await _getAllServerLinks(aliasId.split('\$')[0]);
    //it is a map!, but dart says its not a map :(
    final List<dynamic> eps = serversAndEps[0]['episodes'];
    final List<Map<String, dynamic>> details = [];
    for (int i = 0; i < eps.length; i++) {
      //string which contains the servers
      String serverString = "";
      //string which contains the id's for each servers
      String idString = "";
      serversAndEps.forEach((it) {
        final List<dynamic> ep = it['episodes'];
        idString += "${idString.isEmpty ? "" : ","}${ep[i]['id']}";
        serverString += "${serverString.isEmpty ? "" : ","}${it['server']}";
      });

      //here we give em as "episodeId+servers+anilistId"
      details.add({
        'episodeLink': "$idString+$serverString+$aliasId+${eps[i]['number']}",
        'episodeNumber': eps[i]['number'],
        'episodeTitle': (eps[i]["title"]?.isEmpty ?? true) ? null : eps[i]["title"],
        'thumbnail': (eps[i]['img']?.isEmpty ?? true) ? null : eps[i]["img"],
        'hasDub': eps[i]['hasDub'] ?? false,
        'isFiller': eps[i]['isFiller'] ?? false,
      });
    }

    return details;
  }

  @override
  Future<void> getStreams(String episodeId, Function(List<VideoStream> p1, bool p2) update,
      {bool dub = false, String? metadata}) async {
    final epIdSplit = episodeId.split("+");
    final epId = epIdSplit[0].split(",");
    final servers = epIdSplit[1].split(",");
    final anilistId = epIdSplit[2].split("\$")[0];
    // final malId = epIdSplit[2].split("\$")[1];
    final epNum = epIdSplit[3];

    int serversFetched = 0;

    servers.forEach((it) {
      final link = getWatchUrl(it, epNum, anilistId);
      final itIndex = servers.indexOf(it);
      final currentServersEpId = epId[itIndex];
      final resFuture = post(Uri.parse(link),
          headers: {
            "Content-Type": "application/json",
            'Next-Action': "7f56d3175d4abc2bde60a5dd3b64c25ba1f9b1a39a",
          },
          body: "[\"$anilistId\", \"$it\", \"${currentServersEpId}\", \"$epNum\", \"${dub ? 'dub' : 'sub'}\"]");
      resFuture.onError((e, st) {
        print(e.toString());
        return Response("", 401);
      });
      resFuture.then((res) {
        final split = res.body.split('1:')[1];
        final List<dynamic>? parsed = jsonDecode(split)['sources'];

        if (parsed == null) {
          serversFetched++;
          update([], serversFetched == servers.length);

          return;
        }

        final List<Map<String, dynamic>>? subtitleArr = List.castFrom(jsonDecode(split)?['subtitles'] ?? []);
        final subtitleItem = subtitleArr?.where((st) => st['lang'] == "English").firstOrNull; // We only need english

        //choosing this since the quality is changeable in the default
        final stream = parsed.where((element) => element['quality'] == "default").firstOrNull;
        if (stream != null) {
          serversFetched++;
          update([
            VideoStream(
              quality: "multi-quality",
              link: stream['url'],
              isM3u8: stream['url'].endsWith(".m3u8"),
              server: it,
              backup: false,
            )
          ], serversFetched == servers.length);
        } else {
          //just add all the available streams if couldnt find any default quality ones
          final List<VideoStream> srcs = [];
          serversFetched++;
          for (final str in parsed) {
            if (str['url'] == null) continue;
            try {
              final yukiHeader = {"Referer": "https://megacloud.club/"};
              srcs.add(VideoStream(
                quality: str['quality'] ?? "unknown",
                link: str['url'],
                isM3u8: str['url'].endsWith(".m3u8"),
                server: it,
                backup: (str['quality'] ?? "") == "backup",
                customHeaders: it == "yuki" ? yukiHeader : null,
                subtitle: subtitleItem?['url'],
                subtitleFormat: subtitleItem != null
                    ? subtitleItem['url'].endsWith("vtt")
                        ? SubtitleFormat.VTT.name
                        : SubtitleFormat.ASS.name
                    : null,
              ));
            } catch (err) {
              print(err);
              rethrow;
            }
          }
          update(srcs, serversFetched == servers.length);
        }
      });
    });
    return;
  }

  String getWatchUrl(String server, String epnum, String anilistId) {
    return "$baseUrl/anime/watch/$anilistId?ep=$epnum?host=${server}&type=sub";
  }

  @override
  Future<List<Map<String, String?>>> search(String query) async {
    //this is much faster since the aniplay search uses anilist
    final sr = await Anilist().search(query);
    final List<Map<String, String>> res = [];
    for (final item in sr) {
      res.add({
        'name': item.title['english'] ?? item.title['romaji'] ?? "_null_",
        'alias': item.id.toString() + "\$" + item.idMal.toString(),
        'imageUrl': item.cover,
      });
    }
    return res;
  }

  Future<List<dynamic>> _getAllServerLinks(String id) async {
    final l = "https://aniplaynow.live/anime/info/" + id;
    final res = await post(Uri.parse(l),
        headers: {
          'Referer': l,
          "Content-Type": "text/plain;charset=UTF-8",
          'Next-Action': "7fd497d29b50e7263fd58c8b4873b458476172233a",
        },
        body: "[\"$id\",true,false]");
    final split = res.body.split('1:')[1];
    final List<dynamic> parsed = jsonDecode(split);

    final List<dynamic> servers = [];

    for (final item in parsed) {
      servers.add({
        'server': item['providerId'],
        'episodes': item['episodes'],
      });
    }

    return servers;
  }

  @override
  Future<void> getDownloadSources(String episodeUrl, Function(List<VideoStream> p1, bool p2) update, {bool dub = false, String? metadata}) {
    throw UnimplementedError();
  }
}
