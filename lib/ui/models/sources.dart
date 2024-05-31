import 'package:animestream/core/anime/providers/animepahe.dart';
import 'package:animestream/core/anime/providers/gogoanime.dart';
import 'package:animestream/core/anime/providers/ryuk.dart';
import 'package:animestream/core/anime/providers/types.dart';
import 'package:animestream/core/commons/extractQuality.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';
import 'package:animestream/core/commons/types.dart';

final List sources = ["gogoanime", "ryuk", "animepahe"];

AnimeProvider getClass(String source) {
  switch (source) {
    case "gogoanime":
      return GogoAnime();
    case "ryuk": 
      return Ryuk();
    case "animepahe":
      return AnimePahe();
    default:
      throw new Exception("Invalid source");
  }
}

List<DropdownMenuEntry> getSourceDropdownList() {
  List<DropdownMenuEntry> widget = [];
  int count = 0;
  for (String source in sources) {
    widget.add(
      DropdownMenuEntry(
        value: source,
        label: source,
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(Colors.white),
          textStyle: WidgetStatePropertyAll(
            TextStyle(
              color:  textMainColor,
              fontFamily: "Rubik",
              fontSize: 18,
            )
          )
        )
      ),
    );
    count = count++;
  }
  return widget;
}

Future<List<Map<String, String?>>> searchInSource(String source, String query) async {
  if(query.isEmpty) throw new Exception("ERR_EMPTY_QUERY");
  final searchResults = await getClass(source).search(query);
  return searchResults;
}

Future<List<String>> getAnimeEpisodes(String source, String link) async {
  final info = await getClass(source).getAnimeEpisodeLink(link);

  //should be list of strings
  return info;
  // final int episodes = info['episodes'];
  // List<String> episodeLinks = [];
  // for (int i = 1; i <= episodes; i++) {
  //   episodeLinks.add("${info['link']}$i");
  // }
  // return episodeLinks;
}

generateQualitiesForMultiQuality(String link) async {
  // final qualities = await Vidstream().generateQualityStreams(link);
  final qualities = await getQualityStreams(link);
  return qualities;
}

getStreams(String source, String episodeId, Function(List<Stream>, bool) updateFunction) async {
  final streams = await getClass(source).getStreams(episodeId,  updateFunction);
  return streams;
}
