

import 'package:animestream/core/anime/extractors/streamwish.dart';

void main() async {
  final link = "https://awish.pro/e/d5qwjwstbh8h";
  final i = await StreamWish().extract(link);
  print(i);
}