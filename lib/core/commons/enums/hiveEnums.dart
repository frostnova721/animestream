import 'package:flutter/foundation.dart';

enum HiveKey {
  userPreferences,
  settings,
  theme,
  watching,
  animeSpecificPreference,

  @deprecated
  token,
}

enum HiveBox {
  animestream("animestream"),
  animeInfo("animeInfo"),
  misc("misc"),
  downloadHistory("download_history"),
  animeProviders("anime_providers");

  final String _rawName;

  const HiveBox(this._rawName);

  String get boxName {
    if (kDebugMode) {
      return "dev_$_rawName";
    }
    return _rawName;
  }
}
