String remoteCode() => r'''
import 'package:test/main.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'dart:math';
import 'dart:convert';

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
    list.add(bodyDecoded['data']);
    final int totalPages = bodyDecoded['last_page'];

    for (int i = 1; i < totalPages; i++) {
      if (i > 5) break; //sorry long episoded anime fans, its just not worth 40 requests. the time it gon take is huge!
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
  Future<void> getStreams(String episodeUrl, Function(List<VideoStream> list, bool) update,
      {bool dub = false, String? metadata}) async {
    return await getDownloadSources(episodeUrl, update);
  }

  Future<void> getDownloadSources(String episodeUrl, Function(List<VideoStream> list, bool) update) async {
    
  }
}

AnimeProvider createProvider() => AnimePahe();
''';
