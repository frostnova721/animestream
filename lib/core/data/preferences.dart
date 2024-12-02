import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/data/hive.dart';
import 'package:animestream/core/data/types.dart';

class UserPreferences {
  Future<UserPreferencesModal> getUserPreferences() async {
    Map<dynamic, dynamic>? prefMap = await getVal(HiveKey.userPreferences);
    if(prefMap == null || prefMap.isEmpty) prefMap = UserPreferencesModal().toMap();
    return UserPreferencesModal.fromMap(prefMap);
  }

  Future<void> saveUserPreferences(UserPreferencesModal userPreferences) async {
    final mapped = userPreferences.toMap();
    await storeVal(HiveKey.userPreferences, mapped);
  }
}