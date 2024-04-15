import 'package:animestream/core/data/hive.dart';
import 'package:animestream/core/data/types.dart';

class UserPreferences {
  Future<UserPreferencesModal> getUserPreferences() async {
    final prefMap = await getVal('userPreferences');
    return UserPreferencesModal.fromMap(prefMap);
  }

  Future<void> saveUserPreferences(UserPreferencesModal userPreferences) async {
    final mapped = userPreferences.toMap();
    await storeVal('userPreferences', mapped);
  }
}