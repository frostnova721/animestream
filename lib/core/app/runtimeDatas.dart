import 'package:animestream/core/data/models.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/ui/theme/types.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';

//saved anilist data
UserModel? storedUserData;

//saved settings
SettingsModel? currentUserSettings;

//user prefs
UserPreferencesModel? userPreferences;

//saved theme
late AnimeStreamTheme appTheme;

late String animeOnsenToken;