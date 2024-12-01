enum SettingKey {
  megaSkipDuration,
  skipDuration
}

enum RequestType { recentlyUpdatedAnime, media, mutate }

enum Type { watch, download }

enum MediaStatus { CURRENT, PLANNING, COMPLETED, DROPPED, PAUSED }

enum SortType { AtoZ, RecentlyUpdated, TopRated }

enum SecureStorageKey { 
  simklToken("simkl_token");
 
  final String value;

  const SecureStorageKey(this.value);
}