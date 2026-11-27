import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/data/hive.dart';
import 'package:animestream/core/commons/enums/hiveEnums.dart';
import 'package:animestream/core/data/models/userPreferencesModel.dart';

class UserPreferences {
  static Future<UserPreferencesModel> getUserPreferences() async {
    Map<dynamic, dynamic>? prefMap = await getVal(HiveKey.userPreferences);
    print(prefMap);
    if (prefMap == null || prefMap.isEmpty) {
      print("Got empty list of preferences.");
      return UserPreferencesModel.defaults();
    }
    return UserPreferencesModel.fromMap(prefMap);
  }

  static Future<void> saveUserPreferences(UserPreferencesModel userPref) async {
    Map<dynamic, dynamic>? prefMap = await getVal(HiveKey.userPreferences);
    if (prefMap == null || prefMap.isEmpty) {
      print("Got empty list of preferences.");
      prefMap = UserPreferencesModel.defaults().toMap();
    }
    final mapped = userPref.toMap();
    mapped.forEach((k, v) {
      if (v != null) {
        prefMap![k] = mapped[k];
      }
    });
    print(prefMap);
    userPreferences = UserPreferencesModel.fromMap(prefMap);
    await storeVal(HiveKey.userPreferences, prefMap);
  }
}
