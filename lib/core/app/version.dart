import 'package:package_info_plus/package_info_plus.dart';

class AppVersion {
  /// App's version
  late final String version;

  AppVersion._();

  static AppVersion? _instance;

  static AppVersion get instance {
    if (_instance != null) return _instance!;
    else throw Exception("AppVersion has not yet been initialised.");
  }

  /// Initialises the instance, Loads version
  static Future<void> init() async {
    final info = await PackageInfo.fromPlatform();
    final instance = AppVersion._();
    instance.version = info.version;
    _instance = instance;
  }

  /// Codename
  final String nickname = 'Moonrise';
}