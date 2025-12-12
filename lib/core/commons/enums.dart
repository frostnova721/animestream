import 'package:flutter/foundation.dart';

enum RequestType { recentlyUpdatedAnime, media, mutate }

enum ServerSheetType { watch, download }

enum MediaStatus { CURRENT, PLANNING, COMPLETED, DROPPED, PAUSED }

enum SortType { AtoZ, RecentlyUpdated, TopRated }

enum EpisodeViewModes { tile, grid, list }

enum SubtitleFormat {
  ASS,
  VTT,
  SRT;

  static SubtitleFormat fromName(String name) {
    return switch (name.toLowerCase()) {
      "vtt" => SubtitleFormat.VTT,
      "ass" => SubtitleFormat.ASS,
      "srt" => SubtitleFormat.SRT,
      _ => throw ArgumentError("$name doesnt exist on SubtitleFormat enum"),
    };
  }
}

enum SecureStorageKey {
  //tokens
  simklToken("simkl_token"),
  anilistToken("anilist_token"),
  malToken("mal_token"),

  //auth objects
  malAuthResponse("mal_auth_response"),

  //codes
  malChallengeVerifier("mal_challenge_verifier");

  final String _rawName;

  const SecureStorageKey(this._rawName);

  // Seperation of concern for the debug & release builds
  String get value {
    if (kDebugMode) {
      return "dev_$_rawName";
    }
    return _rawName;
  }
}

enum PlayerState {
  playing,
  paused,
  buffering,
}
