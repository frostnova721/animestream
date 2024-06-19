

import 'package:animestream/core/anime/extractors/kwik.dart';
import 'package:animestream/core/anime/providers/animepahe.dart';

void main() async {
   AnimePahe().getStreams('https://animepahe.ru/play/98d7619c-622d-ba9c-d032-0f962b829470/dd39e48c58663c63e9502800f6771f3eb4c5de9af8137b69100c497b662aa706', (list, b) {
    print(list[0].link);
  });
}