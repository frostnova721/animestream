// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/database/database.dart';
import 'package:animestream/ui/models/widgets/subtitles/subtitleSettings.dart';

class SettingsModal {
  /// Skip duration in seconds for the player
  final int? skipDuration;

  /// Mega skip duration in seconds for the player
  final int? megaSkipDuration;

  /// Error display errors as snackbars
  final bool? showErrors;

  /// Enable pre-release update notifications
  final bool? receivePreReleases;

  /// AMOLED background for dark mode
  final bool? amoledBackground;

  /// Preferred quality for the player
  final String? preferredQuality; // 1080p | 720p |480p | 360p as string

  /// The trasparency of the homescreen navbar
  final double? navbarTranslucency; //value from 0 to 1

  /// Enable faster downloads using increased batch size
  final bool? fasterDownloads;

  /// Preferred source provider for playback
  final String? preferredProvider;

  /// App's dark mode state
  final bool? darkMode;

  /// Use material you theming (just the pallette)
  final bool? materialTheme;

  /// Dev access
  final bool? isDev;

  /// The preferred download path for anime/banner downloads
  final String? downloadPath;

  /// The preferred database provider (SIMKL/MAL/AL)
  final Databases? database;

  /// Enable extra speed options in player (4x,5x,8x,10x)
  final bool? enableSuperSpeeds;

  /// Download items one by one instead of parallel downloads
  final bool? useQueuedDownloads;

  /// Use frameless window (Windows only, not used rn)
  final bool? useFramelessWindow;

  /// Enable double tap to skip in player (Not available for desktops)
  final bool? doubleTapToSkip;

  /// Use native titles (japanese/korean) when available instead of romaji/english
  final bool? nativeTitle;

  /// Enable picture in picture mode on minimize (Not available for desktops)
  final bool? enablePipOnMinimize;

  /// Automatically skip opening and ending themes
  final bool? autoOpEdSkip;

  /// Enable logging throughout the app
  final bool? enableLogging;

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
    this.nativeTitle,
    this.enablePipOnMinimize,
    this.autoOpEdSkip,
    this.enableLogging,
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
      nativeTitle: map['nativeTitle'] ?? false,
      enablePipOnMinimize: map['enablePipOnMinimize'] ?? false,
      autoOpEdSkip: map['autoOpEdSkip'] ?? false,
      enableLogging: map['enableLogging'] ?? false,
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
      'nativeTitle': nativeTitle,
      'enablePipOnMinimize': enablePipOnMinimize,
      'autoOpEdSkip': autoOpEdSkip,
      'enableLogging': enableLogging,
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
      subtitleSettings:
          map['subtitleSettings'] != null ? SubtitleSettings.fromMap(map['subtitleSettings']) : SubtitleSettings(),
      preferDubs: map['preferDubs'] ?? false,
      searchPageListMode: map['searchPageListMode'] ?? false,
    );
  }

  factory UserPreferencesModal.defaults() {
    return UserPreferencesModal(
      episodesViewMode: EpisodeViewModes.list,
      preferDubs: false,
      searchPageListMode: false,
      subtitleSettings: SubtitleSettings(),
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
      lastWatchDuration:
          map['lastWatchDuration'] != null ? Map.from(map['lastWatchDuration'] as Map<dynamic, dynamic>) : null,
      manualSearchQuery: map['manualSearchQuery'] != null ? map['manualSearchQuery'] as String : null,
      preferredProvider: map['preferredProvider'] != null ? map['preferredProvider'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory AnimeSpecificPreference.fromJson(String source) =>
      AnimeSpecificPreference.fromMap(json.decode(source) as Map<String, dynamic>);
}
