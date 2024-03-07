import 'package:animestream/core/app/update.dart';
import 'package:animestream/core/database/anilist/anilist.dart';

void main() async {
// final data = await Anilist().getTrending();
final data = await checkForUpdates();
print(data);
}