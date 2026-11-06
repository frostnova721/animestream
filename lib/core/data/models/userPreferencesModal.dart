import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/ui/models/widgets/subtitles/subtitleSettings.dart';

class UserPreferencesModal {
  final EpisodeViewModes? episodesViewMode;
  final SubtitleSettings? subtitleSettings;
  final bool? preferDubs;
  final bool? searchPageListMode;
  final bool? autoSelectPreviouslyUsedServer;
  UserPreferencesModal({
    this.episodesViewMode,
    this.subtitleSettings,
    this.preferDubs,
    this.searchPageListMode,
    this.autoSelectPreviouslyUsedServer,
  });

  factory UserPreferencesModal.fromMap(Map<dynamic, dynamic> map) {
    return UserPreferencesModal(
      episodesViewMode: getViewModeEnum(map['episodesViewMode'] ?? 0),
      subtitleSettings:
          map['subtitleSettings'] != null ? SubtitleSettings.fromMap(map['subtitleSettings']) : SubtitleSettings(),
      preferDubs: map['preferDubs'] ?? false,
      searchPageListMode: map['searchPageListMode'] ?? false,
      autoSelectPreviouslyUsedServer: map['autoSelectPreviouslyUsedServer'] ?? false,
    );
  }

  factory UserPreferencesModal.defaults() {
    return UserPreferencesModal(
      episodesViewMode: EpisodeViewModes.list,
      preferDubs: false,
      searchPageListMode: false,
      subtitleSettings: SubtitleSettings(),
      autoSelectPreviouslyUsedServer: false,
    );
  }

  Map<dynamic, dynamic> toMap() {
    return {
      'episodesViewMode': episodesViewMode != null ? getViewModeIndex(episodesViewMode!) : null,
      'subtitleSettings': subtitleSettings?.toMap(),
      'preferDubs': preferDubs,
      'searchPageListMode': searchPageListMode,
      'autoSelectPreviouslyUsedServer': autoSelectPreviouslyUsedServer,
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