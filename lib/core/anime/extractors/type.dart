import 'package:animestream/core/anime/providers/models.dart';

abstract class AnimeExtractor {
  Future<List<VideoStream>> extract(String streamUrl);
}
