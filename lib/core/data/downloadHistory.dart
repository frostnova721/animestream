import 'package:animestream/core/anime/downloader/downloaderHelper.dart';
import 'package:animestream/core/anime/downloader/types.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DownloadHistory {
  static const _boxName = "download_history";

  static Future<void> initBox() => Hive.openBox(_boxName);

  static ValueListenable<Box> get listenable => Hive.box(_boxName).listenable();

  // lets keep this box open forever lol
  // static Future<void> closeBox() => Hive.box(_boxName).close();

  static List<DownloadHistoryItem> getDownloadHistory({DownloadStatus status = DownloadStatus.completed}) {
    final box = Hive.box(_boxName);
    final filtered = <DownloadHistoryItem>[];
    box.values.forEach((e) {
      if (e['status'] == status.name) filtered.add(DownloadHistoryItem.fromMap(Map.castFrom(e)));
    });
    return filtered;
  }

  static Future<void> saveItem(DownloadHistoryItem item) async {
    final box = Hive.box(_boxName);
    int id = item.id;
    while (box.containsKey(id)) {
      id = DownloaderHelper.generateId();
    }
    if (box.values.length > 100) {
      final sorted = box.keys.toList().cast<int>()
        ..sort((a, b) {
          final int at = box.get(a)['timestamp'];
          final int bt = box.get(b)['timestamp'];
          return at.compareTo(bt);
        });
      final deletable = sorted.sublist(100);
      await box.deleteAll(deletable);
    }
    await box.put(item.id, item.toMap());
  }

  static Future<void> removeItem(int id) async {
    final box = Hive.box(_boxName);
    await box.delete(id);
  }

  static Future<void> clearAll() async {
    final box = Hive.box(_boxName);
    await box.clear();
  }
}
