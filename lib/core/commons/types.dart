import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/database/types.dart';

class Stream {
  final String quality;
  final String link;
  final bool isM3u8;
  final String? subtitle;
  final SubtitleFormat? subtitleFormat;
  final String server;
  final bool backup;
  final Map<String, String>? customHeaders;

  Stream(
      {required this.quality,
      required this.link,
      required this.isM3u8,
      required this.server,
      required this.backup,
      this.subtitleFormat = null,
      this.subtitle = null, 
      this.customHeaders = null,
      });
}

class ServerSelectionBottomSheetContentData {
  final int episodeIndex;
  final String title;
  final List<String> epLinks;
  final String selectedSource;
  final int id;
  final String cover;
  final int? totalEpisodes;
  final double? lastWatchDuration;

  ServerSelectionBottomSheetContentData({
    required this.episodeIndex,
    required this.epLinks,
    required this.selectedSource,
    required this.title,
    required this.id,
    required this.cover,
    required this.lastWatchDuration,
    this.totalEpisodes,
  });
}

class WatchPageInfo {
  int episodeNumber;
  final String animeTitle;
  Stream streamInfo;
  int id;
  List<AlternateDatabaseId> altDatabases;
  double? lastWatchDuration;

  WatchPageInfo({
    required this.id,
    required this.animeTitle,
    required this.episodeNumber,
    required this.streamInfo,
    required this.altDatabases,
    required this.lastWatchDuration,
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
