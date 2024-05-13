abstract class AnimeProvider {
  Future<List<Map<String, String?>>> search(String query);

  Future<Map<String, dynamic>> getAnimeEpisodeLink(String aliasId);

  Future<void> getStreams(String episodeId, Function(List<dynamic>, bool) update);
}
