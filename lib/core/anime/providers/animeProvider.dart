import 'package:animestream/core/anime/providers/types.dart';

abstract class AnimeProvider {
  /**Name of the provider */
  String get providerName;

  //should provide search results with keys: name, image, alias
  Future<List<Map<String, String?>>> search(String query);

  /**
   * Should return a list of string that is the link to get to that episode
   */
  Future<List<Map<String, dynamic>>> getAnimeEpisodeLink(String aliasId, { bool dub = false });

  /**
   * The link format returned in the [getAnimeEpisodeLink] method should be
   * parsed in this method
   */
  Future<void> getStreams(String episodeId, Function(List<VideoStream>, bool) update, { bool dub = false, String? metadata });

  /**
   * The link format returned in the [getAnimeEpisodeLink] method should be
   * parsed in this method
   * 
   * This method should return a list of [VideoStream] objects containing direct download
   * links to the episode
   */
  Future<void> getDownloadSources(String episodeUrl, Function(List<VideoStream>, bool) update, {bool dub = false, String? metadata});
}
