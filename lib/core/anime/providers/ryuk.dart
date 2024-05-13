import 'package:animestream/core/anime/extractors/ryuk.dart';
import 'package:animestream/core/anime/providers/types.dart';
import 'package:animestream/core/commons/utils.dart';
import 'package:html/parser.dart';

class Ryuk extends AnimeProvider {
  final baseUrl = "https://ryuk.to";

  Future<List<Map<String, String?>>> search(String query) async {
    final res = await fetch("${baseUrl}/search?keyword=$query");
    final doc = await parse(res);
    List<Map<String, String?>> searchResults = [];
    doc.querySelector(".film_list-wrap")!.children.forEach((element) {
      final title = element.querySelector('.film-poster-ahref')?.attributes['title'];

      //unused for now!!
      // final romajiTitle =
      // element.querySelector('.film-poster-ahref')!.attributes['data-jname'];

      final imageUrl = element.querySelector('.film-poster-img')!.attributes['data-src'];
      final link = element.querySelector('.film-poster-ahref')!.attributes['href'];
      searchResults.add({'name': title, 'alias': link?.replaceAll("/anime/", '') ?? '', 'imageUrl': imageUrl});
    });
    return searchResults;
  }

  Future<List<Map<String, String>>> getAllServerLinks(String epUrl) async {
    final res = await fetch(epUrl);
    final doc = parse(res);
    List<Map<String, String>> servers = [];
    doc.querySelector('.ps__-list')!.children.forEach((element) {
      final name = element.text.trim();
      final link = element.children[0].attributes['href'];
      if (link != null) servers.add({'server': name.toLowerCase(), 'src': link});
    });
    return servers;
  }

  Future<Map<String, dynamic>> getAnimeEpisodeLink(String alias) async {
    final res = await fetch("$baseUrl/anime/$alias");
    final doc = parse(res);
    int totalEpisodes = 0;
    doc.querySelector('.anisc-info')!.children.forEach((elem) {
      final textContent = elem.text;
      if (textContent.contains('Episodes:')) {
        totalEpisodes = int.parse(textContent.replaceAll('Episodes:', '').trim());
      }
    });
    return {
      'link': "$baseUrl/watch/$alias-episode-",
      'episodes': totalEpisodes,
    };
  }

  Future<void> getStreams(String episodeId, Function(List<dynamic>, bool) update) async {
    //get link of all servers
    final servers = await getAllServerLinks(episodeId);

    final ryukLink = _getServerLink("ryuk server", servers);

    //update when more servers are added!!
    final totalStreams = 1;
    int returns = 0;

    final ryuk = RyukExtractor().extract(ryukLink);

    ryuk.then((res) {
      returns++;
      update(res, returns == totalStreams);
    }).catchError((error) {
      print(error);
      returns++;
      update([], returns == totalStreams);
    });
  }

  String _getServerLink(String serverName, List<Map<String, String>> servers) {
    final src = servers.where((element) => element['server']?.toLowerCase() == serverName.toLowerCase()).toList();
    if (src.isEmpty) {
      return '';
    }
    return src[0]['src'] ?? '';
  }
}
