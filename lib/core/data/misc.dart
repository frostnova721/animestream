import 'package:animestream/core/commons/enums/hiveEnums.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Used for storage of keys from providers. nothing else

Future<dynamic> getMiscVal(String key) async {
  final box = await Hive.openBox(HiveBox.misc.boxName);
  final stuff = await box.get(key);
  await box.close();
  return stuff;
}

Future<void> storeMiscVal(String key, dynamic value) async {
  final box = await Hive.openBox(HiveBox.misc.boxName);
  await box.put(key, value);
  await box.close();
  return;
}
