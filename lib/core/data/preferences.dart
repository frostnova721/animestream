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
    final mapped = userPref.toMap();
    userPreferences = userPref;
    await storeVal(HiveKey.userPreferences, mapped);
  }
}