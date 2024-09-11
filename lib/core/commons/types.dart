class Stream {
  final String quality;
  final String link;
  final bool isM3u8;
  final String? subtitle;
  final String server;
  final bool backup;

  Stream(
      {required this.quality,
      required this.link,
      required this.isM3u8,
      required this.server,
      required this.backup,
      this.subtitle = null});
}

class ServerSelectionBottomSheetContentData {
  final int episodeIndex;
  final String title;
  final List<String> epLinks;
  final String selectedSource;
  final int id;
  final String cover;
  final int? totalEpisodes;

  ServerSelectionBottomSheetContentData({
    required this.episodeIndex,
    required this.epLinks,
    required this.selectedSource,
    required this.title,
    required this.id,
    required this.cover,
    this.totalEpisodes,
  });
}

class WatchPageInfo {
  int episodeNumber;
  final String animeTitle;
  Stream streamInfo;
  int id;

  WatchPageInfo({
    required this.id,
    required this.animeTitle,
    required this.episodeNumber,
    required this.streamInfo,
  });
}

class HomePageList {
  final String coverImage;
  final double? rating;
  final Map<String, String?> title;
  final int id;
  final int? totalEpisodes;
  final int? watchedEpisodeCount;

  HomePageList({
    required this.coverImage,
    required this.rating,
    required this.title,
    required this.id,
    this.totalEpisodes,
    this.watchedEpisodeCount,
  });
}

class Subtitle {
  final Duration start;
  final Duration end;
  final String dialogue;
  // final String

  Subtitle({
    required this.dialogue,
    required this.end,
    required this.start,
  });
}
