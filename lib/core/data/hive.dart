import 'package:animestream/core/commons/enums/hiveEnums.dart';
import 'package:hive/hive.dart';

Future<dynamic>? getVal(HiveKey itemKey, {HiveBox boxName = HiveBox.animestream}) async {
  var box = await Hive.openBox(boxName.boxName);
  if (!box.isOpen) {
    box = await Hive.openBox(boxName.boxName);
  }
  final vals = await box.get(itemKey.name);
  await box.close();
  return vals;
}

Future<void> storeVal(HiveKey itemKey, dynamic val, {HiveBox boxName = HiveBox.animestream}) async {
  try {
    var box = await Hive.openBox(boxName.boxName);
    if (!box.isOpen) {
      box = await Hive.openBox(boxName.boxName);
    }
    await box.put(itemKey.name, val);
    await box.close();
  } catch (err) {
    print(err);
  }
}
