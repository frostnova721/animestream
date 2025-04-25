import 'package:animestream/core/anime/providers/types.dart';
import 'package:animestream/core/database/types.dart';

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
  VideoStream streamInfo;
  int id;
  List<AlternateDatabaseId> altDatabases;
  double? lastWatchDuration;
  List<VideoStream> allStreams;

  WatchPageInfo({
    required this.id,
    required this.animeTitle,
    required this.episodeNumber,
    required this.streamInfo,
    required this.altDatabases,
    required this.lastWatchDuration,
    this.allStreams = const [],
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
