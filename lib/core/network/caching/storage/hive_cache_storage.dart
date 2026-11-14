import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

import 'package:animestream/core/network/caching/domain/cache_entry.dart';
import 'package:animestream/core/network/caching/storage/cache_storage.dart';
import 'package:hive/hive.dart';

class CacheEntryAdapter extends TypeAdapter<CacheEntry> {
  @override
  final int typeId = 120;

  @override
  CacheEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CacheEntry(
      key: fields[0] as String? ?? '',
      bodyBytes: CacheEntry.toBytes(fields[1]),
      etag: fields[2] as String?,
      lastModified: fields[3] as String?,
      expiry: fields[4] as DateTime? ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  @override
  void write(BinaryWriter writer, CacheEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.key)
      ..writeByte(1)
      ..write(obj.bodyBytes)
      ..writeByte(2)
      ..write(obj.etag)
      ..writeByte(3)
      ..write(obj.lastModified)
      ..writeByte(4)
      ..write(obj.expiry);
  }
}

class HiveCacheStorage implements CacheStorage {
  final String boxName;

  HiveCacheStorage({this.boxName = 'network_cache_box'});

  String _safeKey(String key) {
    if (key.length <= 250) return key;
    final hash = md5.convert(utf8.encode(key)).toString();
    return '${key.substring(0, 100)}..._$hash';
  }

  Future<Box<CacheEntry>> _getBox() async {
    if (!Hive.isAdapterRegistered(120)) {
      Hive.registerAdapter(CacheEntryAdapter());
    }
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<CacheEntry>(boxName);
    }
    return await Hive.openBox<CacheEntry>(boxName);
  }

  @override
  Future<void> init() async {
    await _getBox();
  }

  @override
  Future<CacheEntry?> get(String key) async {
    final box = await _getBox();
    return box.get(_safeKey(key));
  }

  @override
  Future<void> put(String key, CacheEntry entry) async {
    final box = await _getBox();
    final sk = _safeKey(key);
    entry.key = sk;
    await box.put(sk, entry);
  }

  @override
  Future<void> delete(String key) async {
    final box = await _getBox();
    await box.delete(_safeKey(key));
  }

  @override
  Future<int> deleteExpired(DateTime now) async {
    final box = await _getBox();
    final keysToDelete = box.values
        .where((entry) => entry.expiry.isBefore(now))
        .map((entry) => entry.key)
        .toList();

    if (keysToDelete.isNotEmpty) {
      await box.deleteAll(keysToDelete);
    }
    return keysToDelete.length;
  }

  @override
  Future<int> getCacheSize() async {
    final box = await _getBox();
    if (box.path != null) {
      final file = File(box.path!);
      if (await file.exists()) {
        return await file.length();
      }
    }
    int totalBytes = 0;
    for (final entry in box.values) {
      totalBytes += entry.bodyBytes.length + entry.key.length + 32;
    }
    return totalBytes;
  }

  @override
  Future<void> clear() async {
    final box = await _getBox();
    await box.clear();
  }

  @override
  Future<List<CacheEntry>> getAll() async {
    final box = await _getBox();
    return box.values.toList();
  }

  @override
  Future<void> deleteKeys(List<String> keys) async {
    if (keys.isEmpty) return;
    final box = await _getBox();
    await box.deleteAll(keys);
  }
}
