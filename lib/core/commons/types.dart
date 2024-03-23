class Stream {
  final String quality;
  final String link;
  final bool isM3u8;
  final String server;
  final bool backup;

  Stream({
    required this.quality,
    required this.link,
    required this.isM3u8,
    required this.server,
    required this.backup,
  });
}

class BottomSheetContentData {
  final int episodeIndex;
  final String title;
  final List<String> epLinks;
  final String selectedSource;
  final int id;
  final String cover;

  BottomSheetContentData({
    required this.episodeIndex,
    required this.epLinks,
    required this.selectedSource,
    required this.title,
    required this.id,
    required this.cover
  });
}

class WatchPageInfo {
  int episodeNumber;
  final String animeTitle;
  dynamic streamInfo;
  int id;

  WatchPageInfo({
    required this.id,
    required this.animeTitle,
    required this.episodeNumber,
    required this.streamInfo,
  });
}

