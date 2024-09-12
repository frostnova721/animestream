import 'dart:convert';

import 'package:animestream/core/anime/providers/types.dart';
import 'package:animestream/core/commons/types.dart';
import 'package:animestream/ui/models/subtitles.dart';
import 'package:http/http.dart';

class AnimeOnsen extends AnimeProvider {
  final _apiHeader = {
    "Authorization":
        "Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImRlZmF1bHQifQ.eyJpc3MiOiJodHRwczovL2F1dGguYW5pbWVvbnNlbi54eXovIiwiYXVkIjoiaHR0cHM6Ly9hcGkuYW5pbWVvbnNlbi54eXoiLCJpYXQiOjE3MjU5OTM3NzgsImV4cCI6MTcyNjU5ODU3OCwic3ViIjoiMDZkMjJiOTYtNjNlNy00NmE5LTgwZmMtZGM0NDFkNDFjMDM4LmNsaWVudCIsImF6cCI6IjA2ZDIyYjk2LTYzZTctNDZhOS04MGZjLWRjNDQxZDQxYzAzOCIsImd0eSI6ImNsaWVudF9jcmVkZW50aWFscyJ9.x9DJgac4z3-phVAYWGMurFGayH3MW1AQJJm8AGu0IvdAI1DpYsWm-6bc1FebHlb-OuT34GMvTngwYPACvBOhlLjvCh4J1BfYHGQJivHRnNDh_1xymdvf0F7T7h2iHeUuu5NzP4c0o17UQqGx1XZ_gjpFY8LdOt6E64XEQhDd1utpjxDSQUDAlwe6fyZoPC6t2tHFNGjmQealFjTfxUfk4fxFQCGvZf0zXhe08gVXa1tsKtNVN4Fjdymi_AITv8L3boJYSgYQbjVTlf_XsIdbolhshRO9sV3LfQxt-F7C2ARah7FzMVrtieSyco11-sR2Y2alHDBWOf6Lk4Ik4AA5Wg",
    // "Content-Type": "application/json"
  };

  @override
  Future<List<String>> getAnimeEpisodeLink(String aliasId) async {
    final baseUrl = 'https://api.animeonsen.xyz/v4/content/${aliasId}/episodes';
    final res = await get(Uri.parse(baseUrl), headers: _apiHeader);
    final Map<String, dynamic> jsoned = jsonDecode(res.body);

    List<String> episodes = [];

    for(final item in jsoned.keys) {
      //we adding this as combination of alias and ep num
      episodes.add("$item+$aliasId");
    }

    return episodes;
  }

  @override
  Future<void> getStreams(String episodeId, Function(List<Stream> p1, bool p2) update) async {
    final animeId = episodeId.split("+")[1];
    final episodeNumber = episodeId.split("+")[0];
     final baseUrl = "https://cdn.animeonsen.xyz/video/mp4-dash/${animeId}/${episodeNumber}/manifest.mpd";
     final subtitleUrl = "https://api.animeonsen.xyz/v4/subtitles/${animeId}/en-US/${episodeNumber}";
    final result = Stream(quality: "single", link: baseUrl, isM3u8: false, server: "animeonsen", backup: false, subtitle: subtitleUrl, subtitleFormat: SubtitleFormat.ASS);

    update([result], true);
  }

  @override
  Future<List<Map<String, String?>>> search(String query) async {
    final baseUrl = "https://search.animeonsen.xyz/indexes/content/search";
    final body = {
      "q": query,
      "limit": 5,
    };

    final headers = {
      "Authorization": "Bearer 0e36d0275d16b40d7cf153634df78bc229320d073f565db2aaf6d027e0c30b13",
      "Content-Type": "application/json",
    };

    final res = await post(Uri.parse(baseUrl), headers: headers, body: jsonEncode(body));

    final List<Map<String, String>> searchResults = [];

    final jsoned = jsonDecode(res.body);

    jsoned['hits'].forEach((item) {
      searchResults.add({
        'name': item['content_title'],
        'alias': item['content_id'],
        'imageUrl': "https://api.animeonsen.xyz/v4/image/210x300/${item['content_id']}",
      });
    });

    return searchResults;
  }
}
