import 'dart:convert';

import 'package:animestream/core/anime/providers/types.dart';
import 'package:animestream/core/commons/types.dart';
import 'package:animestream/core/database/anilist/anilist.dart';
import 'package:http/http.dart';

class AniPlay extends AnimeProvider {
  static const baseUrl = "https://aniplaynow.live";

  @override
  Future<List<String>> getAnimeEpisodeLink(String aliasId) async {
    final serversAndEps = await _getAllServerLinks(aliasId.split('\$')[0]);
    //it is a map!, but dart says its not a map :(
    final List<dynamic> eps = serversAndEps[0]['episodes'];
    final List<String> epIds = [];
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
      epIds.add("$idString+$serverString+$aliasId+${eps[i]['number']}");
    }

    return epIds;
  }

  @override
  Future<void> getStreams(String episodeId, Function(List<VideoStream> p1, bool p2) update) async {
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
            'Next-Action': "5dbcd21c7c276c4d15f8de29d9ef27aef5ea4a5e",
          },
          body: "[\"$anilistId\", \"$it\", \"${currentServersEpId}\", \"$epNum\", \"sub\"]");
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
            try {
              srcs.add(VideoStream(
                quality: str['quality'] ?? "unknown",
                link: str['url'],
                isM3u8: str['url'].endsWith(".m3u8"),
                server: it,
                backup: (str['quality'] ?? "") == "backup",
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
          'Next-Action': "f3422af67c84852f5e63d50e1f51718f1c0225c4",
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
  Future<void> getDownloadSources(String episodeUrl, Function(List<VideoStream> p1, bool p2) update) {
     throw UnimplementedError();
  }
}
