class SettingsModal {
  final int? skipDuration;
  final int? megaSkipDuration;
  final bool? showErrors;

  SettingsModal({
    this.megaSkipDuration,
    this.skipDuration,
    this.showErrors
  });

  factory SettingsModal.fromMap(Map<dynamic, dynamic> map) {
    return SettingsModal(
      megaSkipDuration: map['megaSkipDuration'] ?? 85,
      skipDuration: map['skipDuration'] ?? 10,
      showErrors: map['showErrors'] ?? false,
    );
  }

  Map<dynamic, dynamic> toMap() {
    return {
      'skipDuration': skipDuration,
      'megaSkipDuration': megaSkipDuration,
      'showErrors': showErrors,
    };
  }
}