import 'package:animestream/core/commons/types.dart';

abstract class AnimeExtractor {
  Future<List<VideoStream>> extract(String streamUrl);
}
