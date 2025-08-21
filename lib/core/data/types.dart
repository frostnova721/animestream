// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/database/database.dart';
import 'package:animestream/ui/models/widgets/subtitles/subtitleSettings.dart';

class SettingsModal {
  final int? skipDuration;
  final int? megaSkipDuration;
  final bool? showErrors;
  final bool? receivePreReleases;
  final bool? amoledBackground;
  final String? preferredQuality; // 1080p | 720p |480p | 360p as string
  final double? navbarTranslucency; //value from 0 to 1
  final bool? fasterDownloads;
  final String? preferredProvider;
  final bool? darkMode;
  final bool? materialTheme;
  final bool? isDev;
  final String? downloadPath;
  final Databases? database;
  final bool? enableSuperSpeeds;
  final bool? useQueuedDownloads;
  final bool? useFramelessWindow;
  final bool? doubleTapToSkip;

  SettingsModal({
    this.megaSkipDuration,
    this.skipDuration,
    this.showErrors,
    this.receivePreReleases,
    this.amoledBackground,
    this.preferredQuality,
    this.navbarTranslucency,
    this.fasterDownloads,
    this.preferredProvider,
    this.darkMode,
    this.materialTheme,
    this.isDev,
    this.downloadPath,
    this.database,
    this.enableSuperSpeeds,
    this.useQueuedDownloads,
    this.useFramelessWindow,
    this.doubleTapToSkip,
  });

  factory SettingsModal.fromMap(Map<dynamic, dynamic> map) {
    return SettingsModal(
      megaSkipDuration: map['megaSkipDuration'] ?? 85,
      skipDuration: map['skipDuration'] ?? 10,
      showErrors: map['showErrors'] ?? false,
      receivePreReleases: map['receivePreReleases'] ?? false,
      amoledBackground: map['amoledBackground'] ?? false,
      preferredQuality: map['preferredQuality'] ?? "720p",
      navbarTranslucency: map['navbarTranslucency'] ?? 1.0,
      fasterDownloads: map['fasterDownloads'] ?? false,
      preferredProvider: map['preferredProvider'] ?? null,
      darkMode: map['darkMode'] ?? true,
      materialTheme: map['materialTheme'] ?? false,
      isDev: map['isDev'] ?? false,
      downloadPath: map['downloadPath'], // No default value since we can assign them at runtime according to OS
      database: DatabaseFromString.getDb(map['database'] ?? "anilist"),
      enableSuperSpeeds: map['enableSuperSpeeds'] ?? false,
      useQueuedDownloads: map['useQueuedDownloads'] ?? false,
      useFramelessWindow: map['useFramelessWindow'] ?? false,
      doubleTapToSkip: map['doubleTapToSkip'] ?? true,
    );
  }

  Map<dynamic, dynamic> toMap() {
    return {
      'skipDuration': skipDuration,
      'megaSkipDuration': megaSkipDuration,
      'showErrors': showErrors,
      'receivePreReleases': receivePreReleases,
      'amoledBackground': amoledBackground,
      'preferredQuality': preferredQuality,
      'navbarTranslucency': navbarTranslucency,
      'fasterDownloads': fasterDownloads,
      'preferredProvider': preferredProvider,
      'darkMode': darkMode,
      'materialTheme': materialTheme,
      'isDev': isDev,
      'downloadPath': downloadPath,
      'database': database?.name,
      'enableSuperSpeeds': enableSuperSpeeds,
      'useQueuedDownloads': useQueuedDownloads,
      'useFramelessWindow': useFramelessWindow,
      'doubleTapToSkip': doubleTapToSkip,
    };
  }
}

class UserPreferencesModal {
  final EpisodeViewModes? episodesViewMode;
  final SubtitleSettings? subtitleSettings;
  final bool? preferDubs;
  final bool? searchPageListMode;

  UserPreferencesModal({
    this.episodesViewMode,
    this.subtitleSettings,
    this.preferDubs,
    this.searchPageListMode,
  });

  factory UserPreferencesModal.fromMap(Map<dynamic, dynamic> map) {
    return UserPreferencesModal(
      episodesViewMode: getViewModeEnum(map['episodesViewMode'] ?? 0),
      subtitleSettings: map['subtitleSettings'] != null ? SubtitleSettings.fromMap(map['subtitleSettings']) : SubtitleSettings(),
      preferDubs: map['preferDubs'] ?? false,
      searchPageListMode: map['searchPageListMode'] ?? false,
    );
  }

  Map<dynamic, dynamic> toMap() {
    return {
      'episodesViewMode': episodesViewMode != null ? getViewModeIndex(episodesViewMode!) : null,
      'subtitleSettings': subtitleSettings?.toMap(),
      'preferDubs': preferDubs,
      'searchPageListMode': searchPageListMode,
    };
  }

  static EpisodeViewModes getViewModeEnum(int modeIndex) {
    switch (modeIndex) {
      case 0:
        return EpisodeViewModes.list;
      case 1:
        return EpisodeViewModes.grid;
      case 2:
        return EpisodeViewModes.tile;
      default:
        throw Exception("Unknown index for episode view mode enum");
    }
  }

  static int getViewModeIndex(EpisodeViewModes mode) {
    switch (mode) {
      case EpisodeViewModes.tile:
        return 2;
      case EpisodeViewModes.grid:
        return 1;
      case EpisodeViewModes.list:
        return 0;
    }
  }
}

class AnimeSpecificPreference {
  final Map? lastWatchDuration;
  final String? manualSearchQuery;
  final String? preferredProvider;

  AnimeSpecificPreference({
    this.lastWatchDuration,
    this.manualSearchQuery,
    this.preferredProvider,
  });

  @override
  String toString() =>
      'AnimeSpecificPreference(lastWatchDuration: $lastWatchDuration, manualSearchQuery: $manualSearchQuery, preferredProvider: $preferredProvider)';

  AnimeSpecificPreference copyWith({
    Map? lastWatchDuration,
    String? manualSearchQuery,
    String? preferredProvider,
  }) {
    return AnimeSpecificPreference(
      lastWatchDuration: lastWatchDuration ?? this.lastWatchDuration,
      manualSearchQuery: manualSearchQuery ?? this.manualSearchQuery,
      preferredProvider: preferredProvider ?? this.preferredProvider,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'lastWatchDuration': lastWatchDuration,
      'manualSearchQuery': manualSearchQuery,
      'preferredProvider': preferredProvider,
    };
  }

  factory AnimeSpecificPreference.fromMap(Map<String, dynamic> map) {
    return AnimeSpecificPreference(
      lastWatchDuration: map['lastWatchDuration'] != null ? Map.from(map['lastWatchDuration'] as Map<dynamic,dynamic>) : null,
      manualSearchQuery: map['manualSearchQuery'] != null ? map['manualSearchQuery'] as String : null,
      preferredProvider: map['preferredProvider'] != null ? map['preferredProvider'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory AnimeSpecificPreference.fromJson(String source) => AnimeSpecificPreference.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(covariant AnimeSpecificPreference other) {
    if (identical(this, other)) return true;
  
    return 
      other.lastWatchDuration == lastWatchDuration &&
      other.manualSearchQuery == manualSearchQuery &&
      other.preferredProvider == preferredProvider;
  }

  @override
  int get hashCode => lastWatchDuration.hashCode ^ manualSearchQuery.hashCode ^ preferredProvider.hashCode;
}
