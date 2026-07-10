import 'dart:async';

import 'package:animestream/core/network/caching/storage/cache_config_storage.dart';
import 'package:animestream/core/network/caching/storage/hive_cache_config_storage.dart';
import 'package:flutter/foundation.dart';

class CacheConfig {
  final int maxCacheSize;
  final bool enableCaching;
  final bool bypassCache;

  const CacheConfig({
    this.maxCacheSize = 200 * 1024 * 1024,
    this.enableCaching = true,
    this.bypassCache = false,
  });

  CacheConfig copyWith({
    int? maxCacheSize,
    bool? enableCaching,
    bool? bypassCache,
  }) {
    return CacheConfig(
      maxCacheSize: maxCacheSize ?? this.maxCacheSize,
      enableCaching: enableCaching ?? this.enableCaching,
      bypassCache: bypassCache ?? this.bypassCache,
    );
  }

  factory CacheConfig.fromMap(Map<dynamic, dynamic> map) {
    return CacheConfig(
      maxCacheSize: map['maxCacheSize'] as int? ?? 1024 * 1024 * 1024,
      enableCaching: map['enableCaching'] as bool? ?? true,
      bypassCache: map['bypassCache'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'maxCacheSize': maxCacheSize,
      'enableCaching': enableCaching,
      'bypassCache': bypassCache,
    };
  }

  factory CacheConfig.fromJson(Map<String, dynamic> json) =>
      CacheConfig.fromMap(json);

  Map<String, dynamic> toJson() => toMap();
}

class CacheConfigController extends ValueNotifier<CacheConfig> {
  Timer? _debounce;
  final CacheConfigStorage _storage;

  static CacheConfigController? _instance;
  static CacheConfigController get instance =>
      _instance ??= CacheConfigController._internal(
        storage: HiveCacheConfigStorage(),
      );

  factory CacheConfigController({CacheConfigStorage? storage}) {
    if (storage != null) {
      return CacheConfigController._internal(storage: storage);
    }
    return instance;
  }

  CacheConfigController._internal({required CacheConfigStorage storage})
      : _storage = storage,
        super(const CacheConfig()) {
    _loadFromDb();
  }

  Future<void> _loadFromDb() async {
    final loaded = await _storage.load();
    if (loaded != null) {
      value = loaded;
    }
  }

  void setMaxCacheSize(int maxCacheSize) {
    value = value.copyWith(maxCacheSize: maxCacheSize);
    _saveDb();
  }

  void setEnableCaching(bool enableCaching) {
    value = value.copyWith(enableCaching: enableCaching);
    _saveDb();
  }

  void setBypassCache(bool bypassCache) {
    value = value.copyWith(bypassCache: bypassCache);
    _saveDb();
  }

  void _saveDb() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _storage.save(value);
    });
  }
}

final cacheConfigController = CacheConfigController.instance;
