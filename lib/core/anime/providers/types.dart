import 'package:animestream/core/commons/types.dart';

abstract class AnimeProvider {
  Future<List<Map<String, String?>>> search(String query);

  // Future<Map<String, dynamic>> 
  Future<List<String>> getAnimeEpisodeLink(String aliasId);

  Future<void> getStreams(String episodeId, Function(List<Stream>, bool) update);
}
