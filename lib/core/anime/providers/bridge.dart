import 'package:animestream/core/anime/providers/transformer.dart';
import 'package:animestream/core/anime/providers/animeProvider.dart';
import 'package:animestream/core/anime/providers/types.dart';

class AnimeProviderBridge implements AnimeProvider {
  @override
  Future<List<Map<String, dynamic>>> getAnimeEpisodeLink(String aliasId, {bool dub = false}) {
    // TODO: implement getAnimeEpisodeLink
    throw UnimplementedError();
  }

  @override
  Future<void> getDownloadSources(String episodeUrl, Function(List<VideoStream> p1, bool p2) update, {bool dub = false, String? metadata}) {
    // TODO: implement getDownloadSources
    throw UnimplementedError();
  }

  @override
  Future<void> getStreams(String episodeId, Function(List<VideoStream> p1, bool p2) update, {bool dub = false, String? metadata}) {
    // TODO: implement getStreams
    throw UnimplementedError();
  }

  @override
  // TODO: implement providerName
  String get providerName => throw UnimplementedError();

  @override
  Future<List<Map<String, String?>>> search(String query) {
    // TODO: implement search
    throw UnimplementedError();
  }
  
}
