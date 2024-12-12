import 'package:animestream/core/data/types.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/ui/models/subtitles.dart';
import 'package:animestream/ui/theme/types.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

//saved anilist data
UserModal? storedUserData;

//saved settings
SettingsModal? currentUserSettings;

//saved theme
late AnimeStreamTheme appTheme;

//active theme's themeItem
late ThemeItem activeThemeItem;

//saved subtitle settings
late SubtitleSettings subtitleSettings;

late String animeOnsenToken;

String simklClientId = dotenv.get("SIMKL_CLIENT_ID");