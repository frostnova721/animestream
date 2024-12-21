
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/database/database.dart';
import 'package:animestream/core/database/mal/mal.dart';
import 'package:animestream/core/database/mal/types.dart';
import 'package:http/http.dart';

class MALMutation extends DatabaseMutation {
  @override
  Future<MALMutationResult?> mutateAnimeList(
      {required int id,
      MediaStatus? status = MediaStatus.CURRENT,
      int? progress = 0,
      MediaStatus? previousStatus}) async {
    final url = "https://api.myanimelist.net/v2/anime/$id/my_list_status";
    final body = {'status': stringifyMediaStatus(status!), 'num_watched_episodes': '$progress'};
    final header = {
      ...(await MAL.getHeader()),
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    await put(
      Uri.parse(url),
      headers: header,
      body: body,
    ); 
    return MALMutationResult();
  }

  String stringifyMediaStatus(MediaStatus ms) {
    switch (ms) {
      case MediaStatus.COMPLETED:
        return "completed";
      case MediaStatus.CURRENT:
        return "watching";
      case MediaStatus.PAUSED:
        return "on_hold";
      case MediaStatus.DROPPED:
        return "dropped";
      case MediaStatus.PLANNING:
        return "plan_to_watch";
    }
  }
}
