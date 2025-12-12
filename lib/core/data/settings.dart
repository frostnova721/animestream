import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums/hiveEnums.dart';
import 'package:animestream/core/data/types.dart';
import 'package:hive/hive.dart';

class Settings {
  static final String _boxName = HiveBox.animestream.boxName;

  Future<SettingsModal> getSettings({bool writing = false}) async {
    var box = await Hive.openBox(_boxName);
    if (!box.isOpen) box = await Hive.openBox(_boxName);
    Map<dynamic, dynamic> settings = await box.get(HiveKey.settings.name) ?? {};
    if (settings.isEmpty) settings = SettingsModal().toMap();
    final classed = SettingsModal.fromMap(settings);
    if (!writing) await box.close();
    return classed;
  }

  Future<void> writeSettings(SettingsModal settings) async {
    var box = await Hive.openBox(_boxName);
    if (!box.isOpen) box = await Hive.openBox(_boxName);
    var currentSettings = (await getSettings(writing: true)).toMap();
    var updatedSettings = settings.toMap();
    print("before updation: $currentSettings");
    print("value upation: $updatedSettings");
    currentSettings.forEach((key, value) {
      if (updatedSettings[key] != null) {
        currentSettings[key] = updatedSettings[key];
      }
    });
    currentUserSettings = SettingsModal.fromMap(currentSettings);
    await box.put(HiveKey.settings.name, currentSettings);
    if (box.isOpen) await box.close;
  }
}
