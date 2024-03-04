class SettingsModal {
  final int skipDuration;
  final int megaSkipDuration;

  SettingsModal({
    this.megaSkipDuration = 85,
    this.skipDuration = 10,
  });

  factory SettingsModal.fromMap(Map<dynamic, dynamic> map) {
    return SettingsModal(
      megaSkipDuration: map['megaSkipDuration'] ?? 85,
      skipDuration: map['skipDuration'] ?? 10,
    );
  }

  Map<dynamic, dynamic> toMap() {
    return {
      'skipDuration': skipDuration,
      'megaSkipDuration': megaSkipDuration,
    };
  }
}

enum SettingKey {
  megaSkipDuration,
  skipDuration
}
