import 'package:animestream/core/commons/types.dart';

abstract class AnimeProvider {
  //should provide search results with keys: name, image, alias
  Future<List<Map<String, String?>>> search(String query);

  /**
   * Should return a list of string that is the link to get to that episode
   */
  Future<List<String>> getAnimeEpisodeLink(String aliasId);

  /**
   * The link format returned in the [getAnimeEpisodeLink] method should be
   * parsed in this method
   */
  Future<void> getStreams(String episodeId, Function(List<Stream>, bool) update);

  /**
   * The link format returned in the [getAnimeEpisodeLink] method should be
   * parsed in this method
   * 
   * This method should return a list of [Stream] objects containing direct download
   * links to the episode
   */
  Future<void>? getDownloadSources(String episodeUrl, Function(List<Stream>, bool) update);
}
