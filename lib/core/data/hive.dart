import 'package:animestream/core/commons/enums.dart';
import 'package:hive/hive.dart';

Future<dynamic>? getVal(HiveKey itemKey, {String boxName = 'animestream'}) async {
  var box = await Hive.openBox(boxName);
  if (!box.isOpen) {
    box = await Hive.openBox(boxName);
  }
  final vals = await box.get(itemKey.name);
  await box.close();
  return vals;
}

Future<void> storeVal(HiveKey itemKey, dynamic val, {String boxName = 'animestream'}) async {
  try {
    var box = await Hive.openBox(boxName);
    if (!box.isOpen) {
      box = await Hive.openBox(boxName);
    }
    await box.put(itemKey.name, val);
    await box.close();
  } catch (err) {
    print(err);
  }
}
