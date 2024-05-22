import 'package:animestream/core/commons/types.dart';

abstract class AnimeExtractor {
  Future<List<Stream>> extract(String streamUrl);
}
