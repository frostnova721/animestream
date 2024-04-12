import 'package:animestream/core/anime/extractors/ryuk.dart';
import 'package:animestream/core/anime/providers/ryuk.dart';


void main() async {
 //nope! nothing!
 final sr = await Ryuk().search("oreshura");
 print(sr);
 final episodeLink = await Ryuk().getAnimeEpisodeLink(sr[0]['alias']!);
 print(episodeLink);
 final streams = await Ryuk().getStreams(episodeLink['link']+"1", (list, finish) {
  if(finish) print("finished");
  print(list);
 });
}
