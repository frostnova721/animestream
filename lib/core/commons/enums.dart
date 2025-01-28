enum SettingKey { megaSkipDuration, skipDuration }

enum RequestType { recentlyUpdatedAnime, media, mutate }

enum Type { watch, download }

enum MediaStatus { CURRENT, PLANNING, COMPLETED, DROPPED, PAUSED }

enum SortType { AtoZ, RecentlyUpdated, TopRated }

enum EpisodeViewModes { tile, grid, list }

enum SubtitleFormat { ASS, VTT }

enum HiveKey {
  manualSearches,
  userPreferences,
  settings,
  theme,
  watching,
  animeOnsenToken,
  lastWatchDuration,

  @deprecated
  token,
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

  final String value;

  const SecureStorageKey(this.value);
}
