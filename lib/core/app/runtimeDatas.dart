import 'package:animestream/core/data/types.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/ui/theme/types.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';

//saved anilist data
UserModal? storedUserData;

//saved settings
SettingsModal? currentUserSettings;

//user prefs
UserPreferencesModal? userPreferences;

//saved theme
late AnimeStreamTheme appTheme;

late String animeOnsenToken;