class SettingsModal {
  final int? skipDuration;
  final int? megaSkipDuration;
  final bool? showErrors;
  final bool? receivePreReleases;

  SettingsModal({this.megaSkipDuration, this.skipDuration, this.showErrors, this.receivePreReleases});

  factory SettingsModal.fromMap(Map<dynamic, dynamic> map) {
    return SettingsModal(
      megaSkipDuration: map['megaSkipDuration'] ?? 85,
      skipDuration: map['skipDuration'] ?? 10,
      showErrors: map['showErrors'] ?? false,
      receivePreReleases: map['receivePreReleases'] ?? false
    );
  }

  Map<dynamic, dynamic> toMap() {
    return {
      'skipDuration': skipDuration,
      'megaSkipDuration': megaSkipDuration,
      'showErrors': showErrors,
      'receivePreReleases': receivePreReleases,
    };
  }
}

class UserPreferencesModal {
  final bool? episodeGridView;

  UserPreferencesModal({
    this.episodeGridView
  });

  factory UserPreferencesModal.fromMap(Map<dynamic, dynamic> map) {
    return UserPreferencesModal(episodeGridView: map['episodeGridView'] ?? false);
  }

  Map<dynamic, dynamic> toMap() {
    return {
      'episodeGridView': episodeGridView ?? false,
    };
  }
}
