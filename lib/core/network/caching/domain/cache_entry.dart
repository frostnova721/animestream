import 'dart:typed_data';

class CacheEntry {
  String key;

  /// Kept as [Uint8List] so Hive stores it as raw bytes (1 byte each). A plain `List<int>`
  /// is written element by element at 8 bytes each and holds a full slot per byte in memory.
  ///
  /// Shared with the [HttpResponse] it came from / is served to, so treat it as read-only.
  Uint8List bodyBytes;
  String? etag;
  String? lastModified;
  DateTime expiry;

  CacheEntry({
    required this.key,
    required this.bodyBytes,
    this.etag,
    this.lastModified,
    required this.expiry,
  });

  /// Accepts both the current [Uint8List] form and the old `List<int>` one.
  static Uint8List toBytes(Object? raw) {
    if (raw is Uint8List) return raw;
    if (raw is List) return Uint8List.fromList(raw.cast<int>());
    return Uint8List(0);
  }

  factory CacheEntry.fromMap(Map<dynamic, dynamic> map) {
    return CacheEntry(
      key: map['key'] as String? ?? '',
      bodyBytes: toBytes(map['bodyBytes']),
      etag: map['etag'] as String?,
      lastModified: map['lastModified'] as String?,
      expiry: DateTime.fromMillisecondsSinceEpoch(map['expiry'] as int? ?? 0),
    );
  }

  Map<dynamic, dynamic> toMap() {
    return {
      'key': key,
      'bodyBytes': bodyBytes,
      'etag': etag,
      'lastModified': lastModified,
      'expiry': expiry.millisecondsSinceEpoch,
    };
  }
}
