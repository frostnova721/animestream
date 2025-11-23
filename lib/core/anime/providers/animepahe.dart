import 'dart:convert';
import 'dart:math';

import 'package:animestream/core/anime/providers/animeProvider.dart';
import 'package:animestream/core/anime/providers/types.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;

class AnimePahe extends AnimeProvider {
  @override
  String providerName = "animepahe";

  final _headers = {
    'Cookie': "__ddg1=;__ddg2_=",
    'referer': "https://animepahe.si/",
  };

  @override
  Future<List<Map<String, String?>>> search(String query) async {
    query = query.replaceAll("-", "");
    final String url = "https://animepahe.si/api?m=search&q=$query";
    final res = await http.get(Uri.parse(url), headers: _headers);
    final Map<String, dynamic> decoded = json.decode(res.body);
    final List<dynamic> results = decoded['data'];
    final List<Map<String, String?>> searchResults = [];
    for (final result in results) {
      searchResults.add({
        'name': result['title'],
        'alias': result['session'],
        'imageUrl': result['poster'],
      });
    }
    return searchResults;
  }

  @override
  Future<List<Map<String, dynamic>>> getAnimeEpisodeLink(String session, {bool dub = false}) async {
    List list = [];
    final String url = "https://animepahe.si/api?m=release&id=$session&sort=episode_asc`";
    final data = await http.get(Uri.parse(url), headers: _headers);
    final bodyDecoded = json.decode(data.body);

    list.add(bodyDecoded['data']);
    final int totalPages = bodyDecoded['last_page'];

    for (int i = 1; i < totalPages; i++) {
      if (i > 5) break; //sorry long episoded anime fans, its just not worth 40 requests. the time it gon take is huge!
      final res = await http.get(Uri.parse("$url&page=${i + 1}"), headers: _headers);
      list.add(json.decode(res.body)['data']);
    }

    list = list.expand((item) => item).toList();

    final List<Map<String, dynamic>> episodeLinks = [];

    for (int i = 0; i < list.length; i++) {
      final episodeLink = "https://animepahe.si/play/$session/${list[i]['session']}";
      final String? thumbnail = list[i]['snapshot'];
      final filler = list[i]['filler'] != 0;
      final String? title = ((list[i]['title'] as String?)?.isEmpty ?? true) ? null : list[i]['title'];
      final bool? dub = list[i]['audio'] != 'jpn';
      episodeLinks.add({
        'episodeLink': episodeLink,
        'episodeNumber': list.length - i,
        'thumbnail': thumbnail,
        'episodeTitle': title,
        'isFiller': filler,
        'hasDub': dub,
      });
    }

    return episodeLinks.reversed.toList();
  }

  @override
  Future<void> getStreams(String episodeUrl, Function(List<VideoStream> list, bool) update,
      {bool dub = false, String? metadata}) async {
    return await getDownloadSources(episodeUrl, update, dub: dub, metadata: metadata);
    // final data = await http.get(Uri.parse(episodeUrl), headers: _headers);
    // final document = html.parse(data.body);
    // final streams = document.querySelectorAll('div#resolutionMenu > button');
    // final links = [];
    // streams.forEach((e) {
    //   final link = e.attributes['data-src'] ?? '';
    //   final text = e.text;
    //   final server = text.split('·')[0].trim();
    //   final quality = text.split('·')[1].trim();
    //   links.add({'link': link, 'server': server, 'quality': quality});
    // });

    // // final servers = document.querySelectorAll('div#pickProvider > button');

    // // servers.forEach((e) {
    // //   final link = e.attributes['data-src'] ?? '';
    // //   final text = e.text;
    // //   final server = text.split('·')[0].trim();
    // //   final quality = text.split('·')[1].trim();
    // //   links.add({'link': link, 'server': server, 'quality': quality});
    // // });

    // final totalStreams = links.length;
    // int returns = 0;

    // links.forEach((e) {
    //   final extracted = Kwik().extract(e['link'], server: e['server'], quality: e['quality']);
    //   extracted.then((res) {
    //     returns++;
    //     update(res, returns == totalStreams);
    //   }).catchError((error) {
    //     print(error);
    //     returns++;
    //     update([], returns == totalStreams);
    //   });
    // });
  }

  Future<void> getDownloadSources(String episodeUrl, Function(List<VideoStream> list, bool) update,
      {bool dub = false, String? metadata}) async {
    final data = await http.get(Uri.parse(episodeUrl), headers: _headers);
    final document = html.parse(data.body);
    final downloadQualities = document.querySelectorAll('div#pickDownload > a');
    final List<Map<String, String>> links = [];
    downloadQualities.forEach((e) {
      final link = e.attributes['href'] ?? '';
      final text = e.text;
      final quality = text.split('·')[1].trim().replaceAll(RegExp(r'\(\d+MB\)'), "");
      final server = text.split('·')[0].trim();
      final size = RegExp(r'(\d+MB)').firstMatch(text);
      links.add({'link': link, 'quality': quality, 'server': server, 'size': size?.group(1) ?? '?? MB'});
    });

    final totalStreams = links.length;
    int returns = 0;

    for (final e in links) {
      final isDub = e['quality']?.toLowerCase().contains('eng') ?? false;
      if (isDub != dub) {
        returns++;
        if (returns == totalStreams) update([], totalStreams == returns);
        continue;
      }
      final downloadLink = _extractDownloadLink(e['link'] ?? '');
      downloadLink.then((val) {
        returns++;
          update([
            VideoStream(
              quality: e['quality']! + " [${e['size']}]",
              server: e['server'] ?? "unknown",
              url: val,
              backup: false,
              subtitle: null,
              subtitleFormat: null,
            ),
          ], returns == totalStreams);
      }).catchError((error) {
        print(error);
        returns++;
        update([], returns == totalStreams);
      });
    }
  }

  final _map = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ+/";

  int _getString(List<String> content, int s1) {
    final s2 = 10;
    final slice = _map.substring(0, s2);
    int acc = 0;
    content.reversed.toList().asMap().forEach((index, c) {
      acc += (RegExp(r'\d').hasMatch(c) ? int.parse(c) : 0) * pow(s1, index).toInt();
    });
    String k = "";
    while (acc > 0) {
      k = slice[acc % s2] + k;
      acc = (acc / s2).floor();
    }
    return int.parse(k);
  }

  String _decrypt(String fullKey, String key, int v1, int v2) {
    String r = "";
    int i = 0;
    while (i < fullKey.length) {
      String s = "";
      while (fullKey[i] != key[v2]) {
        s += fullKey[i];
        i++;
      }
      for (int j = 0; j < key.length; j++) {
        s = s.replaceAll(RegExp(key[j]), j.toString());
      }
      r += String.fromCharCode(_getString(s.split(""), v2) - v1);
      i++;
    }
    return r;
  }

  Future<String> _extractDownloadLink(String downloadLink) async {
    if (downloadLink == '') throw new Exception("Invalid download link");
    final redirectRegex = RegExp(r'\("href","(.*?)"\)');
    final paramRegex = RegExp(r'\("(\w+)",\d+,"(\w+)",(\d+),(\d+),(\d+)\)');
    final urlRegex = RegExp(r'action="(.+?)"');
    final tokenRegex = RegExp(r'value="(.+?)"');

    final resp = await http.get(Uri.parse(downloadLink), headers: {'referer': downloadLink});
    final scripts = html.parse(resp.body).querySelectorAll('script');
    String? kwikLink;
    scripts.forEach((e) {
      if (kwikLink != null) return;
      if (e != '') {
        final match = redirectRegex.allMatches(e.innerHtml);
        if (match.isNotEmpty) {
          kwikLink = match.toList()[1].group(1);
        }
      }
    });
    if (kwikLink == null) throw new Exception("Couldnt extract kwik link");

    final kwikRes = await http.get(Uri.parse(kwikLink ?? ""));
    final cookies = kwikRes.headers['set-cookie'];
    final match = paramRegex.firstMatch(kwikRes.body);
    if (match == null) throw new Exception("Couldnt extract download link");
    final fullKey = match.group(1)!;
    final key = match.group(2)!;
    final v1 = int.parse(match.group(3)!);
    final v2 = int.parse(match.group(4)!);

    final decrypted = _decrypt(fullKey, key, v1, v2);
    final postUrl = urlRegex.firstMatch(decrypted)!.group(1);
    final token = tokenRegex.firstMatch(decrypted)!.group(1);

    try {
      final r2 = await http.post(
        Uri.parse(postUrl!),
        body: {'_token': token},
        headers: {'referer': kwikLink!, 'cookie': cookies!},
      );
      final mp4Url = r2.headers['location'];
      if (mp4Url == null) throw new Exception("Couldnt extract media link");
      return mp4Url;
    } catch (err) {
      print(err);
      rethrow;
    }
  }
}
