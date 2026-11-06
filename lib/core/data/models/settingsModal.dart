import 'package:animestream/core/database/database.dart';

class SettingsModal {
  /// Skip duration in seconds for the player [defaults to 10 seconds]
  final int? skipDuration;

  /// Mega skip duration in seconds for the player [defaults to 85 seconds]
  final int? megaSkipDuration;

  /// Error display errors as snackbars [defaults to false]
  final bool? showErrors;

  /// Enable pre-release update notifications [defaults to false]
  final bool? receivePreReleases;

  /// AMOLED background for dark mode [defaults to false]
  final bool? amoledBackground;

  /// Preferred quality for the player [defaults to 720p]
  final String? preferredQuality; // 1080p | 720p |480p | 360p as string

  /// The trasparency of the homescreen navbar
  final double? navbarTranslucency; //value from 0 to 1

  /// Enable faster downloads using increased batch size [defaults to false]
  final bool? fasterDownloads;

  /// Preferred source provider for playback [defaults to most stable provider available]
  final String? preferredProvider;

  /// App's dark mode state [defaults to true]
  final bool? darkMode;

  /// Use material you theming (just the pallette) [defaults to false]
  final bool? materialTheme;

  /// Dev access [defaults to false]
  final bool? isDev;

  /// The preferred download path for anime/banner downloads [defaults to the OS download path]
  final String? downloadPath;

  /// The preferred database provider (SIMKL/MAL/AL) [defaults to Anilist]
  final Databases? database;

  /// Enable extra speed options in player (4x,5x,8x,10x) [defaults to false]
  final bool? enableSuperSpeeds;

  /// Download items one by one instead of parallel downloads [defaults to false]
  final bool? useQueuedDownloads;

  /// Use frameless window (Windows only, not used rn)
  final bool? useFramelessWindow;

  /// Enable double tap to skip in player (Not available for desktops) [defaults to true]
  final bool? doubleTapToSkip;

  /// Use native titles (japanese/korean) when available instead of romaji/english [defaults to false]
  final bool? nativeTitle;

  /// Enable picture in picture mode on minimize (Not available for desktops) [defaults to false]
  final bool? enablePipOnMinimize;

  /// Automatically skip opening and ending themes [defaults to false]
  final bool? autoOpEdSkip;

  /// Enable logging throughout the app [defaults to false]
  final bool? enableLogging;

  /// Tap and Hold to speed up the player [defaults to true]
  final bool? enableHoldToSpeedUp;

  /// Enable volume and brightness gestures in player screen
  final bool? enablePlayerGestures;

  /// Use the old navbar instead of the new one (Not available for desktops) [defaults to false]
  final bool? useOldNavbar;

  /// Use experimental mkv video convertion
  final bool? useMkvRemuxer;

  /// Enable discord rich presence
  final bool? enableDiscordRichPresence;

  /// Write the subtitle track to video file (only works when using remuxer)
  final bool? writeSubtitleTrackToVideo;

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
    this.enableHoldToSpeedUp,
    this.enablePlayerGestures,
    this.useOldNavbar,
    this.useMkvRemuxer,
    this.enableDiscordRichPresence,
    this.writeSubtitleTrackToVideo,
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
      enableHoldToSpeedUp: map['enableHoldToSpeedUp'] ?? true,
      enablePlayerGestures: map['enablePlayerGestures'] ?? false,
      useOldNavbar: map['useOldNavbar'] ?? false,
      useMkvRemuxer: map['useMkvRemuxer'] ?? true,
      enableDiscordRichPresence: map['enableDiscordRichPresence'] ?? false,
      writeSubtitleTrackToVideo: map['writeSubtitleTrackToVideo'] ?? false,
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
      'enableHoldToSpeedUp': enableHoldToSpeedUp,
      'enablePlayerGestures': enablePlayerGestures,
      'useOldNavbar': useOldNavbar,
      'useMkvRemuxer': useMkvRemuxer,
      'enableDiscordRichPresence': enableDiscordRichPresence,
      'writeSubtitleTrackToVideo': writeSubtitleTrackToVideo,
    };
  }
}
