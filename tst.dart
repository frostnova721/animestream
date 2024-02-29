import 'package:animestream/core/database/anilist/anilist.dart';

void main() async {
// final data = await Anilist().getTrending();
final data = await Anilist().getTrending();
print(data);
}