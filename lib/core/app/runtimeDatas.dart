import 'package:animestream/core/data/types.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/ui/models/subtitles.dart';
import 'package:animestream/ui/theme/types.dart';

//saved anilist data
UserModal? storedUserData;

//saved settings
SettingsModal? currentUserSettings;

//saved theme
late AnimeStreamTheme appTheme;

//saved subtitle settings
late SubtitleSettings subtitleSettings;

late String animeOnsenToken;