import 'package:animestream/core/anime/providers/animeonsen.dart';
import 'package:animestream/core/anime/providers/animepahe.dart';
import 'package:animestream/core/anime/providers/aniplay.dart';
import 'package:animestream/core/anime/providers/gojo.dart';
import 'package:animestream/core/anime/providers/animeProvider.dart';
import 'package:animestream/core/anime/providers/types.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/extractQuality.dart';
import 'package:flutter/material.dart';

final List<String> sources = [
  // "gogoanime", RIP, you shall rest here till the end of this app's life!
  "animepahe",
  "animeonsen",
  "aniplay",
  "gojo",
];

final List<String> unDownloadableSources = [
  //uses mpd which needs ffmpeg to download (makes the app bulky :< )
  "animeonsen",
];

AnimeProvider getClass(String source) {
  switch (source) {
    // case "gogoanime":
      // return GogoAnime();  :(
    case "animepahe":
      return AnimePahe();
    case "animeonsen":
      return AnimeOnsen();
    case "aniplay":
      return AniPlay();
    case "gojo":
      return Gojo();
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
          foregroundColor: WidgetStatePropertyAll(appTheme.textMainColor),
          textStyle: WidgetStatePropertyAll(
            TextStyle(
              color: appTheme.textMainColor,
              fontFamily: "Rubik",
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
    count = count++;
  }
  return widget;
}

Future<List<Map<String, String?>>> searchInSource(String source, String query) async {
  if (query.isEmpty) throw new Exception("ERR_EMPTY_QUERY");
  final searchResults = await getClass(source).search(query);
  return searchResults;
}

Future<List<EpisodeDetails>> getAnimeEpisodes(String source, String link, { bool dub = false}) async {
  final info = await getClass(source).getAnimeEpisodeLink(link, dub: dub);

  // should be list of map corresponding to values of [EpisodeList]
  return info.map((e) => EpisodeDetails.fromMap(e)).toList();
}

Future<List<Map<String, String>>> generateQualitiesForMultiQuality(String link, { Map<String, String>? customHeaders = null}) async {
  if (!link.contains(".m3u8")) return [];
  final qualities = await getQualityStreams(link, customHeader: customHeaders);
  return qualities;
}

Future<void> getDownloadSources(String source, String episodeUrl, Function(List<VideoStream>, bool) updateFunction) async {
  final streams = await getClass(source).getDownloadSources(episodeUrl, updateFunction);
  return streams;
}

Future<void> getStreams(String source, String episodeId, void Function(List<VideoStream>, bool) updateFunction, { bool dub = false, String? metadata}) async {
  final streams = await getClass(source).getStreams(episodeId, updateFunction, dub: dub, metadata: metadata);
  return streams;
}
