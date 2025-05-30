import 'dart:convert';

import 'package:animestream/core/database/simkl/login.dart';
import 'package:http/http.dart';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/data/secureStorage.dart';
import 'package:animestream/core/database/database.dart';
import 'package:animestream/core/database/simkl/types.dart';

class SimklMutation extends DatabaseMutation {
  @override
  Future<SimklMutationResult?> mutateAnimeList({
    required int id,
    int? progress = 0,
    MediaStatus? status,
    MediaStatus? previousStatus,
  }) async {
    // final now = DateTime.now();
    // final utc = '${now.year.toString().padLeft(4, '0')}-'
    //     '${now.month.toString().padLeft(2, '0')}-'
    //     '${now.day.toString().padLeft(2, '0')} '
    // '${now.hour.toString().padLeft(2, '0')}:'
    // '${now.minute.toString().padLeft(2, '0')}:'
    // '${now.second.toString().padLeft(2, '0')}';

    if (!(await SimklLogin.isLoggedIn())) return null;

    //this condition works only for currently watching animes
    if (previousStatus?.name == status?.name)
      syncToHistory(id, progress!);
    else
      addToList(id, status ?? MediaStatus.CURRENT);

    return SimklMutationResult();
  }

  Future addToList(int id, MediaStatus status) async {
    final url = "https://api.simkl.com/sync/add-to-list";
    final body = jsonEncode({
      'shows': [
        {
          'to': getStatusString(status),
          'ids': {
            'simkl': id,
          },
        },
      ],
    });

    final header = await getHeader();
    // final res =
    await post(Uri.parse(url), headers: header, body: body);
    // print(res.statusCode);
    // if(res.statusCode != 200) {
    //   // print(res.body);
    //   throw Exception("Couldnt Sync Simkl [maybe false report]");
    // }
  }

  Future syncToHistory(int id, int progress, {String? bodyString = null}) async {
    final url = "https://api.simkl.com/sync/history";
    List<Map<String, int>> episodes = [];

    String body = bodyString ?? '';

    if (bodyString == null) {
      //generate progress
      for (int i = 0; i < progress; i++) {
        episodes.add({'number': i + 1});
      }

      body = jsonEncode({
        'shows': [
          {
            'ids': {
              'simkl': id,
            },
            'seasons': [
              {'number': 1, "episodes": episodes}
            ],
          },
        ],
      });
    }

    final header = await getHeader();
    final res = await post(Uri.parse(url), headers: header, body: body);
    if (res.statusCode != 201) {
      // print(res.body);
      throw Exception("Couldnt Sync Simkl [maybe false report]");
    }
  }

  static Future<Map<String, String>> getHeader() async {
    final token = await getSecureVal(SecureStorageKey.simklToken);
    if (token == null) {
      throw Exception("SIMKL_SYNC: TOKEN NOT FOUND");
    }
    return {
      'Content-Type': "application/json",
      'Authorization': "Bearer $token",
      'simkl-api-key': simklClientId,
    };
  }

  String getStatusString(MediaStatus status) {
    switch (status) {
      case MediaStatus.COMPLETED:
        return "completed";
      case MediaStatus.CURRENT:
        return "watching";
      case MediaStatus.DROPPED:
        return "dropped";
      case MediaStatus.PAUSED:
        return "onhold";
      case MediaStatus.PLANNING:
        return "plantowatch";
      // default:
      // throw Exception("UNHANDLED MEDIA STATUS CASE");
    }
  }
}
