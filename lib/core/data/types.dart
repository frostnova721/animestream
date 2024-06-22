class SettingsModal {
  final int? skipDuration;
  final int? megaSkipDuration;
  final bool? showErrors;
  final bool? receivePreReleases;
  final bool? amoledBackground;
  final String? preferredQuality;
  final bool? translucentNavbar;

  SettingsModal({
    this.megaSkipDuration,
    this.skipDuration,
    this.showErrors,
    this.receivePreReleases,
    this.amoledBackground,
    this.preferredQuality,
    this.translucentNavbar,
  });

  factory SettingsModal.fromMap(Map<dynamic, dynamic> map) {
    return SettingsModal(
      megaSkipDuration: map['megaSkipDuration'] ?? 85,
      skipDuration: map['skipDuration'] ?? 10,
      showErrors: map['showErrors'] ?? false,
      receivePreReleases: map['receivePreReleases'] ?? false,
      amoledBackground: map['amoledBackground'] ?? false,
      preferredQuality: map['preferredQuality'] ?? "720p",
      translucentNavbar: map['translucentNavbar'] ?? true,
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
      'translucentNavbar': translucentNavbar,
    };
  }
}

class UserPreferencesModal {
  final bool? episodeGridView;

  UserPreferencesModal({this.episodeGridView});

  factory UserPreferencesModal.fromMap(Map<dynamic, dynamic> map) {
    return UserPreferencesModal(episodeGridView: map['episodeGridView'] ?? false);
  }

  Map<dynamic, dynamic> toMap() {
    return {
      'episodeGridView': episodeGridView ?? false,
    };
  }
}
