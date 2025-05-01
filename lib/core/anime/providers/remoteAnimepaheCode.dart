String remoteCode() => r'''
import 'package:provins/classes.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'dart:math';
import 'dart:convert';
import 'dart:collection';

class AnimePahe extends AnimeProvider {
  @override
  String providerName = "animepahe";

  final _headers = {
    'Cookie': "__ddg1=;__ddg2_=",
    'referer': "https://animepahe.ru/",
  };

  @override
  Future<List<Map<String, String?>>> search(String query) async {
    final String url = "https://animepahe.ru/api?m=search&q=$query";
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
    List<dynamic> list = [];
    final String url = "https://animepahe.ru/api?m=release&id=$session&sort=episode_asc`";
    final data = await http.get(Uri.parse(url), headers: _headers);
    final bodyDecoded = json.decode(data.body);
    final int totalPages = bodyDecoded['last_page'];

    list.add(bodyDecoded['data']);

    for (int i = 1; i < totalPages; i++) {
      if (i > 5) break;
      final res = await http.get(Uri.parse("$url&page=${i + 1}"), headers: _headers);
      list.add(json.decode(res.body)['data']);
    }

    List<dynamic> flattened = [];
    for (var sublist in list) {
      if (sublist is Iterable) {
        for (var item in sublist) {
          flattened.add(item);
        }
      }
    }
    list = flattened;

    final List<Map<String, dynamic>> episodeLinks = [];

    for (int i = 0; i < list.length; i++) {
      final episodeLink = "https://animepahe.ru/play/$session/${list[i]['session']}";
      final String? thumbnail = list[i]['snapshot'];
      final filler = list[i]['filler'] != 0;
      final String title = list[i]['title'];
      final bool? dub = list[i]['audio'] != 'jpn';
      episodeLinks.add({
        'episodeLink': episodeLink,
        'episodeNumber': (list.length - i).toString(),
        'thumbnail': thumbnail,
        'episodeTitle': title,
        'isFiller': filler.toString(),
        'hasDub': dub.toString(),
      });
    }

    return episodeLinks.reversed.toList();
  }

  @override
  Future<void> getStreams(String episodeUrl, void Function(List<VideoStream> list, bool) update,
      {bool dub = false, String? metadata}) async {
    await getDownloadSources(episodeUrl, update, dub: dub, metadata: metadata);
    return;
  }

  Future<void> getDownloadSources(String episodeUrl, Function(List<VideoStream> list, bool) update,
      {bool dub = false, String? metadata}) async {
    final data = await http.get(Uri.parse(episodeUrl), headers: _headers);
    final document = html.parse(data.body);
    final downloadQualities = document.querySelectorAll('div#pickDownload > a');
    final List<Map<String, String>> links = [];
    for (var e in downloadQualities) {
      final attr = e.attributes;
      final link = attr['href'] ?? '';
      final String text = e.text;
      final quality = text.split('·')[1].trim().replaceAll(RegExp(r'\(\d+MB\)'), "");
      final server = text.split('·')[0].trim();
      final size = RegExp(r'(\d+MB)').firstMatch(text);
      links.add({'link': link, 'quality': quality, 'server': server, 'size': size?.group(1) ?? '?? MB'});
    }
    final totalStreams = links.length;
    int returns = 0;
    for (final e in links) {
      final isDub = (e['quality'] as String).toLowerCase().contains('eng') ?? false;
      if (isDub != dub) {
        returns++;
        if (returns == totalStreams) update([], totalStreams == returns);
      } else {
        final link = await _extractDownloadLink(e['link'] ?? '');
        // .then((String link) {
          returns++;
          update([
            VideoStream(
              quality: e['quality'] + " [${e['size']}]",
              server: e['server'] ?? "unknown",
              link: link,
              isM3u8: link.contains(".m3u8"),
              backup: false,
              subtitle: null,
              subtitleFormat: null,
            ),
          ], returns == totalStreams);
          // });
          // .catchError((error) {
      //       print(error);
      //       returns++;
      //       update([], returns == totalStreams);
      //     });
      }
    }
    return;
  }

  final _map = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ+/";

  int _getString(List<String> content, int sep) {
    int b = 10;
    final n = _map.substring(0, b);
    double mx = 0;
    for (var index = 0; index < content.length; index++) {
      mx +=
          (int.tryParse(content[content.length - index - 1], radix: 10) ?? 0.0)
              .toInt() *
          (pow(sep, index));
    }
    var m = '';
    while (mx > 0) {
      m = n[(mx % b).toInt()] + m;
      mx = (mx - (mx % b)) / b;
    }
    return m.isNotEmpty ? int.parse(m) : 0;
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
    final redirectRegex = RegExp(r'\.attr\("href",\s*"(https:\/\/kwik\.si\/f\/[^"]+)"\)');
    final paramRegex = RegExp(r'\("(\w+)",\d+,"(\w+)",(\d+),(\d+),(\d+)\)');
    final urlRegex = RegExp(r'action="(.+?)"');
    final tokenRegex = RegExp(r'value="(.+?)"');

    final resp = await http.get(Uri.parse(downloadLink), headers: {'referer': downloadLink});
    final scripts = html.parse(resp.body).querySelectorAll('script');
    String? kwikLink;
    for (final e in scripts) {
      if (e.text != '') {
        final match = redirectRegex.firstMatch(e.innerHtml);
        if (match != null) {
          kwikLink = match.group(1);
          break;
        }
      }
    }
    if (kwikLink == null) throw Exception("Couldnt extract kwik link");

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

AnimeProvider createProvider() => AnimePahe();

''';
