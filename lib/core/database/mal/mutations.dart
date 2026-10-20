import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/database/database.dart';
import 'package:animestream/core/database/mal/login.dart';
import 'package:animestream/core/database/mal/mal.dart';
import 'package:animestream/core/database/mal/types.dart';
import 'package:animestream/core/database/types.dart';
import 'package:animestream/core/network/network.dart';

class MALMutation extends DatabaseMutation {
  /// Mutates the anime list entry for a given anime [id] with the provided parameters.
  ///
  /// Updates the entry with the new [score] (on a scale of 1-10), a new [status]
  /// (which defaults to `CURRENT`), and the new [progress] (defaults to 0).
  ///
  /// You can optionally provide the [previousStatus] if tracking status history.
  @override
  Future<MALMutationResult?> mutateAnimeList(
      {required int id,
      MediaStatus? status = MediaStatus.CURRENT,
      int? progress = 0,
      int? score,
      MediaStatus? previousStatus}) async {
    final url = "https://api.myanimelist.net/v2/anime/$id/my_list_status";
    final body = {
      'status': stringifyMediaStatus(status!),
      'num_watched_episodes': '$progress',
      if (score != null) 'score': '$score',
    };
    final header = {
      ...(await MAL.getHeader()),
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    final res = await put(
      Uri.parse(url),
      headers: header,
      body: body,
    );
    // print(res.statusCode);
    if (res.statusCode == 401) {
      // Retry after refreshing token
      await MALLogin().refreshToken();
      final header = {
        ...(await MAL.getHeader(refreshHeaders: true)),
        'Content-Type': 'application/x-www-form-urlencoded',
      };
      await put(
        Uri.parse(url),
        headers: header,
        body: body,
      );
    }
    return MALMutationResult();
  }

  @override
  Future<DatabaseMutationResult?> deleteAnimeEntry({required int id}) async {
    final url = "https://api.myanimelist.net/v2/anime/$id/my_list_status";
    final headers = {...(await MAL.getHeader())};
    Response res = await delete(Uri.parse(url), headers: headers);

    if (res.statusCode == 401) {
      // Retry after refreshing token
      await MALLogin().refreshToken();
      final headers = {
        ...(await MAL.getHeader(refreshHeaders: true)),
      };
      res = await delete(Uri.parse(url), headers: headers);
    }

    if (res.statusCode == 404) {
      throw Exception("[MAL]: The anime with id: $id doesn't exist in MAL");
    }

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
