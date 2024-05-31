import 'dart:convert';
import 'package:animestream/core/anime/extractors/kwik.dart';
import 'package:animestream/core/anime/providers/types.dart';
import 'package:animestream/core/commons/types.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;

class AnimePahe extends AnimeProvider {
  final _headers = {
    'Cookie': "__ddg1=;__ddg2_=",
    'referer': "https://animepahe.ru/",
  };

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

  Future<List<String>> getAnimeEpisodeLink(String session) async {
    List list = [];
    final String url = "https://animepahe.ru/api?m=release&id=$session&sort=episode_asc`";
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

    final List<String> episodeLinks = [];

    for (int i = 0; i < list.length; i++) {
      final episodeLink = "https://animepahe.ru/play/$session/${list[i]['session']}";
      episodeLinks.add(episodeLink);
    }

    return episodeLinks.reversed.toList();
  }

  Future<void> getStreams(String episodeUrl, Function(List<Stream> list, bool) update) async {
    final data = await http.get(Uri.parse(episodeUrl), headers: _headers);
    final document = html.parse(data.body);
    final streams = document.querySelectorAll('div#resolutionMenu > button');
    final links = [];
    streams.forEach((e) {
      final link = e.attributes['data-src'] ?? '';
      final text = e.text;
      final server = text.split('·')[0].trim();
      final quality = text.split('·')[1].trim();
      links.add({'link': link, 'server': server, 'quality': quality});
    });

    // final servers = document.querySelectorAll('div#pickProvider > button');

    // servers.forEach((e) {
    //   final link = e.attributes['data-src'] ?? '';
    //   final text = e.text;
    //   final server = text.split('·')[0].trim();
    //   final quality = text.split('·')[1].trim();
    //   links.add({'link': link, 'server': server, 'quality': quality});
    // });

    final totalStreams = links.length;
    int returns = 0;

    links.forEach((e) {
      final extracted = Kwik().extract(e['link'], server: e['server'], quality: e['quality']);
      extracted.then((res) {
        returns++;
        update(res, returns == totalStreams);
      }).catchError((error) {
        print(error);
        returns++;
        update([], returns == totalStreams);
      });
    });
  }
}
