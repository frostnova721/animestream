

import 'package:animestream/core/anime/providers/animeonsen.dart';

void main() async {
  final q = "my teen romatic comedy";
  final ao = new AnimeOnsen();
  // final sr = await ao.search(q);
  // print(sr);

  final episodes = await ao.getAnimeEpisodeLink("8apEr1709BnIK7NY");
  print(episodes);
}