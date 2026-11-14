import 'dart:io';
import 'dart:typed_data';

import 'package:animestream/core/network/caching/domain/cache_entry.dart';
import 'package:animestream/core/network/caching/storage/hive_cache_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory dir;

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('cache_storage_test');
    Hive.init(dir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  CacheEntry entry(List<int> bytes) =>
      CacheEntry(key: 'k', bodyBytes: CacheEntry.toBytes(bytes), expiry: DateTime(2100));

  test('stores bodies as raw bytes (about 1 byte per byte on disk)', () async {
    final storage = HiveCacheStorage(boxName: 'raw_bytes');
    final body = List<int>.generate(100000, (i) => i % 256);
    await storage.put('k', entry(body));

    final size = await File('${dir.path}/raw_bytes.hive').length();
    expect(size, lessThan(110000)); // List<int> encoding would be ~800KB

    await Hive.close(); // force a re-read from disk
    final read = await HiveCacheStorage(boxName: 'raw_bytes').get('k');
    expect(read!.bodyBytes, isA<Uint8List>());
    expect(read.bodyBytes, body);
  });

  test('reads entries written in the old List<int> format', () async {
    Hive.registerAdapter(_LegacyAdapter(), override: true);
    final legacyBox = await Hive.openBox<CacheEntry>('legacy');
    await legacyBox.put('k', entry([1, 2, 3]));
    await Hive.close();

    Hive.registerAdapter(CacheEntryAdapter(), override: true);
    final read = await HiveCacheStorage(boxName: 'legacy').get('k');
    expect(read!.bodyBytes, isA<Uint8List>());
    expect(read.bodyBytes, [1, 2, 3]);
  });
}

/// Writes bodyBytes as a plain List<int>, like the app did before.
class _LegacyAdapter extends CacheEntryAdapter {
  @override
  void write(BinaryWriter writer, CacheEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.key)
      ..writeByte(1)
      ..write(List<int>.of(obj.bodyBytes))
      ..writeByte(2)
      ..write(obj.etag)
      ..writeByte(3)
      ..write(obj.lastModified)
      ..writeByte(4)
      ..write(obj.expiry);
  }
}
