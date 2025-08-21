import 'package:animestream/core/anime/providers/animeonsen.dart';
import 'package:animestream/core/anime/providers/animepahe.dart';
import 'package:animestream/core/anime/providers/aniplay.dart';
import 'package:animestream/core/anime/providers/gojo.dart';
import 'package:animestream/core/anime/providers/animeProvider.dart';
import 'package:animestream/core/anime/providers/providerDetails.dart';
import 'package:animestream/core/anime/providers/providerManager.dart';
import 'package:animestream/core/anime/providers/providerPlugin.dart';
import 'package:animestream/core/anime/providers/types.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:flutter/material.dart';

class SourceManager {
  static final SourceManager _instance = SourceManager._internal();
  factory SourceManager() => _instance;
  SourceManager._internal();

  final List<ProviderDetails> inbuiltSources = [
    "Animepahe",
    "AnimeOnsen",
    "Aniplay",
    "Gojo",
  ].map((e) => ProviderDetails(name: e, identifier: e.toLowerCase(), version: "0.0.0.0")).toList();

  /// Used till complete migration to remote providers is complete.
  bool _useInbuiltProviders = true;

  bool get useInbuiltProviders => _useInbuiltProviders;

  set useInbuiltProviders(bool val) => _useInbuiltProviders = val;

  final List<ProviderDetails> _sources = [];

  final ProviderPlugin _plugin = ProviderPlugin();

  List<ProviderDetails> get sources => _sources;

  void addSource(ProviderDetails source) {
    _sources.add(source);
  }

  void addSources(List<ProviderDetails> sources) {
    _sources.addAll(sources);
  }

  void removeSource(String identifier) {
    _sources.removeWhere((e) => e.identifier == identifier);
  }

  Future<void> loadProviders({bool clearBeforeLoading = true}) async {
    final providers = await ProviderManager().getSavedProviders();
    if (clearBeforeLoading) _sources.clear();
    _sources.addAll(providers);
  }

  Future<List<Map<String, String?>>> searchInSource(String source, String query) async {
    if (query.isEmpty) throw new Exception("ERR_EMPTY_QUERY");
    final searchResults = await (await _getProvider(source)).search(query);
    return searchResults;
  }

  Future<List<EpisodeDetails>> getAnimeEpisodes(String source, String link, {bool dub = false}) async {
    final info = await (await _getProvider(source)).getAnimeEpisodeLink(link, dub: dub);

    /// should be list of map corresponding to values of [EpisodeList]
    return info.map((e) => EpisodeDetails.fromMap(e)).toList();
  }

  Future<void> getDownloadSources(String source, String episodeUrl, Function(List<VideoStream>, bool) updateFunction,
      {bool dub = false, String? metadata}) async {
    await (await _getProvider(source)).getDownloadSources(episodeUrl, updateFunction, dub: dub, metadata: metadata);
  }

  Future<void> getStreams(String source, String episodeId, void Function(List<VideoStream>, bool) updateFunction,
      {bool dub = false, String? metadata}) async {
    await (await _getProvider(source)).getStreams(episodeId, updateFunction, dub: dub, metadata: metadata);
  }

  Future<AnimeProvider> _getProvider(String identifier) async {
    final AnimeProvider? provider = _useInbuiltProviders ? getClass(identifier) : await _plugin.getProvider(identifier);
    if (provider == null) throw Exception("$identifier Provider doesnt exist!");
    return provider;
  }
}

// [
//   // "gogoanime", RIP, you shall rest here till the end of this app's life!
//   "Animepahe",
//   "AnimeOnsen",
//   "Aniplay",
//   "Gojo",
// ].map((e) => ProviderDetails(name: e, identifier: e.toLowerCase(), version: "0.0.0.0")).toList()

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
  final sources = SourceManager().sources;
  int count = 0;
  for (final source in sources) {
    widget.add(
      DropdownMenuEntry(
        value: source,
        label: "${source.name}${source.version == "0.0.0.0" ? "" : " [Plugin]"}",
        trailingIcon: source.identifier == currentUserSettings?.preferredProvider ? Icon(Icons.star_border_rounded) : null,
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
