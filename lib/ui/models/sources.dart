import 'package:animestream/core/anime/providers/gogoanime.dart';
import 'package:animestream/core/commons/extractQuality.dart';
import 'package:flutter/material.dart';

final List sources = ["gogoanime"];

getClass(String source) {
  dynamic sourceClass;
  switch (source) {
    case "gogoanime":
      sourceClass = GogoAnime();
    default:
      throw new Exception("Invalid source");
  }

  return sourceClass;
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
          foregroundColor: MaterialStatePropertyAll(Colors.white),
          textStyle: MaterialStatePropertyAll(
            TextStyle(
              color:  Colors.white,
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

searchInSource(String source, String query) async {
  if(query.isEmpty) throw new Exception("ERR_EMPTY_QUERY");
  final searchResults = await getClass(source).search(query);
  return searchResults;
}

getAnimeEpisodes(String source, String link) async {
  final info = await getClass(source).getAnimeEpisodeLink(link);
  final int episodes = info['episodes'];
  List<String> episodeLinks = [];
  for (int i = 1; i <= episodes; i++) {
    episodeLinks.add("${info['link']}$i");
  }
  return episodeLinks;
}

generateQualitiesForMultiQuality(String link) async {
  // final qualities = await Vidstream().generateQualityStreams(link);
  final qualities = await getQualityStreams(link);
  return qualities;
}

getStreams(String source, String episodeId, Function(List<dynamic>, bool) updateFunction) async {
  final streams = await getClass(source).getStreams(episodeId,  updateFunction);
  return streams;
}
