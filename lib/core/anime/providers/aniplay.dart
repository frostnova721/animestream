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
        try {
        final List<dynamic> ep = it['episodes'];
        idString += "${idString.isEmpty ? "" : ","}${ep[i]['id']}";
        serverString += "${serverString.isEmpty ? "" : ","}${it['server']}";
        }  catch(er) {
          print(er.toString());
          print("Index cooked!");
        }
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
    // final keys = await _extractKeys(baseUrl);
    int serversFetched = 0;

    servers.forEach((it) {
      final itIndex = servers.indexOf(it);
      final currentServersEpId = epId[itIndex];
      final link = getWatchUrl(it, epNum, anilistId, currentServersEpId, dub: dub);
      
      final resFuture = get(Uri.parse(link),
          headers: {
            "Content-Type": "text/plain;charset=UTF-8",
            "Referer": "https://aniplaynow.live/anime/watch/$anilistId?host=$it&ep=$epNum&type=${dub? 'dub' : 'sub'}"
            // 'Next-Action': keys['getSources'] ?? '',
          },
          );
          // body: "[\"$anilistId\", \"$it\", \"${currentServersEpId}\", \"$epNum\", \"${dub ? 'dub' : 'sub'}\"]");
      resFuture.onError((e, st) {
        print(e.toString());
        return Response("", 401);
      });
      resFuture.then((res) {
        // final split = res.body.split('1:')[1];
        final Map<dynamic, dynamic>? parsed = jsonDecode(res.body);

        if(parsed == null) {
          serversFetched++;
          update([], serversFetched == servers.length);
          return;
        }

        // print(parsed['source']);

        final List<Map<String, dynamic>>? sources = List.castFrom(parsed['sources'] ?? []);

        if (sources == null || sources.isEmpty) {
          serversFetched++;
          update([], serversFetched == servers.length);

          return;
        }

        final List<Map<String, dynamic>>? subtitleArr = List.castFrom(parsed['subtitles'] ?? []);
        final Map<String, String> headers = Map.from(parsed['headers'] ?? {}).cast<String, String>();
        final subtitleItem = subtitleArr?.where((st) => (st['lang'] ?? st['language']) == "English").firstOrNull; // We only need english

        //here goes my assumptions
        if(headers.isEmpty) headers['Referer'] = "https://megaplay.buzz/";

        //choosing this since the quality is changeable in the default
        final stream = sources.where((element) => element['quality'] == "default").firstOrNull;
        if (stream != null) {
          serversFetched++;
          update([
            VideoStream(
              quality: "multi-quality",
              link: stream['url'],
              customHeaders: headers,
               subtitle: subtitleItem?['url'],
                subtitleFormat: subtitleItem != null
                    ? subtitleItem['url'].endsWith("vtt")
                        ? SubtitleFormat.VTT.name
                        : SubtitleFormat.ASS.name
                    : null,
              server: it,
              backup: false,
            )
          ], serversFetched == servers.length);
        } else {
          //just add all the available streams if couldnt find any default quality ones
          final List<VideoStream> srcs = [];
          serversFetched++;
          for (final str in sources) {
            if (str['url'] == null) continue;
            try {
              srcs.add(VideoStream(
                quality: "multi-quality", // yeah most times (assumptions...)
                link: str['url'],
                server: it,
                backup: str['quality'] == "backup",
                customHeaders: headers,
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

  String getWatchUrl(String server, String epnum, String anilistId, String epId, { bool dub = false}) {
    return "https://aniplaynow.live/api/anime/sources?id=$anilistId&provider=$server&epId=$epId&epNum=$epnum&subType=${dub ? 'dub' : 'sub'}&cache=true";
    // return "$baseUrl/anime/watch/$anilistId?ep=$epnum?host=${server}&type=sub";
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
    final l = "$baseUrl/api/anime/episodes?id=$id&releasing=true&refresh=false";
    // final l = "$baseUrl/anime/info/" + id;
    // final keys = await _extractKeys(baseUrl);
    final res = await get(Uri.parse(l),
        headers: {
          'Referer': "$baseUrl/anime/info/$id",
          "Content-Type": "text/plain;charset=UTF-8",
          // 'Next-Action': keys['getEpisodes'] ?? "",
        },);
        // body: "[\"$id\",true,false]");
    final Map<dynamic,dynamic> parsed = jsonDecode(res.body);

    final List<dynamic> main = parsed['episodes'];

    final List<dynamic> servers = [];

    for (final item in main) {
      servers.add({
        'server': item['providerId'],
        'episodes': item['episodes'],
      });
    }

    return servers;
  }

  @override
  Future<void> getDownloadSources(String episodeUrl, Function(List<VideoStream> p1, bool p2) update,
      {bool dub = false, String? metadata}) {
    throw UnimplementedError();
  }

  // Future<Map<String, String>> _extractKeys(String baseUrl) async {
  //   final prefs = await getMiscVal("aniplayTokens") as List<String>? ?? ["", "0"];
  //   final storedKeys = prefs[0];
  //   final storedTimestamp = int.tryParse(prefs[1]) ?? 0;
  //   final nowTs = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  //   if (nowTs - storedTimestamp < 60 * 60 && storedKeys.contains(baseUrl)) {
  //     return Map<String, String>.from(json.decode(storedKeys));
  //   }

  //   final randomAnimeUrl = "$baseUrl/anime/watch/1";
  //   final res1 = await get(Uri.parse(randomAnimeUrl));
  //   final body1 = res1.body;

  //   final sKey = "/_next/static/chunks/app/(user)/(media)/";
  //   final eKey = '"';
  //   final start = body1.indexOf(sKey);
  //   if (start == -1) throw Exception("Start key not found");

  //   final jsSlugStart = start + sKey.length;
  //   final jsSlugEnd = body1.indexOf(eKey, jsSlugStart);
  //   final jsSlug = body1.substring(jsSlugStart, jsSlugEnd);

  //   final jsUrl = "$baseUrl$sKey$jsSlug";
  //   final res2 = await get(Uri.parse(jsUrl));
  //   final body2 = res2.body;

  //   final regex = RegExp(
  //     r'\(0,\w+\.createServerReference\)\("([a-f0-9]+)",\w+\.callServer,void 0,\w+\.findSourceMapURL,"(getSources|getEpisodes)"\)',
  //     multiLine: true,
  //   );

  //   final matches = regex.allMatches(body2);
  //   final keysMap = <String, String>{};

  //   for (final match in matches) {
  //     final hashId = match.group(1)!;
  //     final functionName = match.group(2)!;
  //     keysMap[functionName] = hashId;
  //   }

  //   keysMap["baseUrl"] = baseUrl;

  //   final newKeys = json.encode(keysMap);
  //   await storeMiscVal("aniplayTokens", [newKeys, nowTs.toString()]);

  //   return keysMap;
  // }
}
