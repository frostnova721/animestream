import 'package:animestream/core/downloader/models/common.dart';

DownloadStatus _getDownloadStatus(String status) => switch (status) {
  "downloading" => DownloadStatus.downloading,
  "queued" => DownloadStatus.queued,
  "paused" => DownloadStatus.paused,
  "completed" => DownloadStatus.completed,
  "cancelled" => DownloadStatus.cancelled,
  "failed" => DownloadStatus.failed,
  _ => throw Exception("Unknown DownloadStats value"),
};

class DownloadHistoryItem {
  final int id; // This id is different from DownloadItem.id!!!
  final DownloadStatus status;
  final int timestamp; // Time of save
  final String? filePath; // Saved path
  final String url; // The download url for pauses/failures?
  final Map<String, String>? headers; // custom headers
  final String fileName;
  final int size; // for confirmation of file (incase of resume after app death)
  final int? lastDownloadedPart; // segment or the data byte

  DownloadHistoryItem({
    required this.id,
    required this.status,
    required this.timestamp,
    required this.filePath,
    required this.url,
    required this.headers,
    required this.fileName,
    required this.size,
    required this.lastDownloadedPart,
  });

  DownloadHistoryItem copyWith({
    int? id,
    DownloadStatus? status,
    int? timestamp,
    String? filePath,
    String? url,
    Map<String, String>? headers,
    String? fileName,
    int? size,
    int? lastDownloadedPart,
  }) {
    return DownloadHistoryItem(
      id: id ?? this.id,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      filePath: filePath ?? this.filePath,
      url: url ?? this.url,
      headers: headers ?? this.headers,
      fileName: fileName ?? this.fileName,
      size: size ?? this.size,
      lastDownloadedPart: lastDownloadedPart ?? this.lastDownloadedPart,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'status': status.name,
      'timestamp': timestamp,
      'filePath': filePath,
      'url': url,
      'headers': headers,
      'fileName': fileName,
      'size': size,
      'lastDownloadedPart': lastDownloadedPart,
    };
  }

  factory DownloadHistoryItem.fromMap(Map<String, dynamic> map) {
    return DownloadHistoryItem(
      id: map['id'] as int,
      status: _getDownloadStatus(map['status']),
      timestamp: map['timestamp'] as int,
      filePath: map['filePath'] != null ? map['filePath'] as String : null,
      url: map['url'] as String,
      headers: map['headers'] != null ? Map<String, String>.from((Map.castFrom(map['headers']))) : null,
      fileName: map['fileName'] as String,
      size: map['size'] as int,
      lastDownloadedPart: map['lastDownloadedPart'] as int?,
    );
  }

  @override
  String toString() {
    return 'DownloadHistoryItem(id: $id, status: $status, timestamp: $timestamp, filePath: $filePath, url: $url, headers: $headers,'
        'fileName: $fileName), size: $size, lastDownloadedPart: $lastDownloadedPart';
  }
}
