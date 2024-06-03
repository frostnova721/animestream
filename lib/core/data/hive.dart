import 'package:hive/hive.dart';

Future<dynamic> getVal(String itemKey, {String boxName = 'animestream'}) async {
  var box = await Hive.openBox(boxName);
  if (!box.isOpen) {
    box = await Hive.openBox(boxName);
  }
  final vals = await box.get(itemKey);
  await box.close();
  return vals;
}

Future<void> storeVal(String itemKey, dynamic val, {String boxName = 'animestream'}) async {
  try {
    var box = await Hive.openBox(boxName);
    if (!box.isOpen) {
      box = await Hive.openBox(boxName);
    }
    await box.put(itemKey, val);
    await box.close();
  } catch (err) {
    print(err);
  }
}
