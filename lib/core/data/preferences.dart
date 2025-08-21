import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/data/hive.dart';
import 'package:animestream/core/data/types.dart';

class UserPreferences {
  static Future<UserPreferencesModal> getUserPreferences() async {
    Map<dynamic, dynamic>? prefMap = await getVal(HiveKey.userPreferences);
    if(prefMap == null || prefMap.isEmpty) {
      print("Got empty list of preferences.");
      return UserPreferencesModal();
    }
    return UserPreferencesModal.fromMap(prefMap);
  }

  static Future<void> saveUserPreferences(UserPreferencesModal userPref) async {
    Map<dynamic, dynamic>? prefMap = await getVal(HiveKey.userPreferences);
    if(prefMap == null || prefMap.isEmpty) {
      print("Got empty list of preferences.");
    }
    final mapped = userPref.toMap();
    prefMap!.forEach((k,v) {
      if (mapped[k] != null) {
        prefMap[k] = mapped[k];
      }
    });
    userPreferences = UserPreferencesModal.fromMap(prefMap);
    await storeVal(HiveKey.userPreferences, prefMap);
  }
}