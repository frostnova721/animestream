import 'package:animestream/core/data/types.dart';
import 'package:hive/hive.dart';

class Settings {
  Future<SettingsModal> getSettings({bool writing = false}) async {
    var box = await Hive.openBox('animestream');
    if (!box.isOpen) box = await Hive.openBox('animestream');
    Map<dynamic, dynamic> settings = await box.get('settings') ?? {};
    if (settings.isEmpty) settings = SettingsModal().toMap();
    final classed = SettingsModal.fromMap(settings);
    if (!writing) await box.close();
    return classed;
  }

  Future<void> writeSettings(SettingsModal settings) async {
    var box = await Hive.openBox('animestream');
    if (!box.isOpen) box = await Hive.openBox('animestream');
    var currentSettings = (await getSettings(writing: true)).toMap();
    var updatedSettings = settings.toMap();
    print(currentSettings);
    print(updatedSettings);
    currentSettings.forEach((key, value) {
      if (value != updatedSettings[key]) {
        currentSettings[key] = updatedSettings[key];
      }
    });

    await box.put('settings', currentSettings);
    if (box.isOpen) await box.close;
  }
}
