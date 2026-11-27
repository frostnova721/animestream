import 'package:animestream/core/app/logging.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums/hiveEnums.dart';
import 'package:animestream/core/data/models/settingsModel.dart';
import 'package:hive/hive.dart';

class Settings {
  static final String _boxName = HiveBox.animestream.boxName;

  Future<SettingsModel> getSettings({bool writing = false}) async {
    var box = await Hive.openBox(_boxName);
    if (!box.isOpen) box = await Hive.openBox(_boxName);
    Map<dynamic, dynamic> settings = await box.get(HiveKey.settings.name) ?? {};
    if (settings.isEmpty) settings = SettingsModel().toMap();
    final classed = SettingsModel.fromMap(settings);
    if (!writing) await box.close();
    return classed;
  }

  Future<void> writeSettings(SettingsModel settings) async {
    var box = await Hive.openBox(_boxName);
    if (!box.isOpen) box = await Hive.openBox(_boxName);
    var currentSettings = (await getSettings(writing: true)).toMap();
    var updatedSettings = settings.toMap();
    Logs.app.log("before updation: $currentSettings");
    Logs.app.log("value upation: $updatedSettings");
    currentSettings.forEach((key, value) {
      if (updatedSettings[key] != null) {
        currentSettings[key] = updatedSettings[key];
      }
    });
    currentUserSettings = SettingsModel.fromMap(currentSettings);
    await box.put(HiveKey.settings.name, currentSettings);
    if (box.isOpen) await box.close;
  }
}
