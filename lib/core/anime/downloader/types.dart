import 'dart:isolate';

import 'package:flutter/foundation.dart';

// some of them here are just for names lol
enum DownloadStatus { downloading, queued, paused, completed, cancelled, failed }

DownloadStatus getDownloadStatus(String status) => switch(status) {
    "downloading" => DownloadStatus.downloading,
    "queued" => DownloadStatus.queued,
    "paused" => DownloadStatus.paused,
    "completed" => DownloadStatus.completed,
    "cancelled" => DownloadStatus.cancelled,
    "failed" => DownloadStatus.failed,

    _ => throw Exception("Unknown DownloadStats value")
  };

class DownloadItem {
  // The download ID
  final int id;

  // The URL to the media to download (can be stream or video file)
  final String url;

  // File name to be saved as
  final String fileName;

  // Custom header for fetching (if any)
  final Map<String, String> customHeaders;

  // Subtitle url
  final String? subtitleUrl;

  // Value to resume from after pausing
  int? lastDownloadedPart;

  // Notifier for UI updation
  final ValueNotifier<int> progressNotifier = ValueNotifier(0);

  int get progress => progressNotifier.value;

  set progress(int prg) {
    progressNotifier.value = prg;
  }

  // Again a notifier for status updation on UI
  final ValueNotifier<DownloadStatus> statusNotifier = ValueNotifier(DownloadStatus.queued);

  // The Download status
  DownloadStatus get status => statusNotifier.value;

  set status(DownloadStatus newStatus) {
    statusNotifier.value = newStatus;
  }

  DownloadItem({
    required this.id,
    required this.url,
    required DownloadStatus status,
    required this.fileName,
    this.customHeaders = const {},
    int progress = 0,
    this.subtitleUrl,
    this.lastDownloadedPart,
  }) {
    progressNotifier.value = progress;
    statusNotifier.value = status;
  }

  DownloadItem copyWith({
    int? id,
    DownloadStatus? status,
    String? url,
    String? fileName,
    Map<String, String>? customHeaders,
    String? subtitleUrl,
  }) {
    return DownloadItem(
      id: id ?? this.id,
      status: status ?? this.status,
      url: url ?? this.url,
      fileName: fileName ?? this.fileName,
      customHeaders: customHeaders ?? this.customHeaders,
      subtitleUrl: subtitleUrl ?? this.subtitleUrl,
    );
  }

  @override
  String toString() {
    return 'DownloadItem(id: $id, status: $status, url: $url, fileName: $fileName, customHeaders: $customHeaders, subtitleUrl: $subtitleUrl)';
  }
}

// For isolates
class DownloadTaskIsolate {
  final String url;
  final String fileName;
  final int id;
  final Map<String, String> customHeaders;
  final int retryAttempts;
  final int parallelBatches;
  final String? subsUrl;
  final SendPort? sendPort;
  // final RootIsolateToken? rootIsolateToken;
  final int resumeFrom;
  String downloadPath;

  DownloadTaskIsolate({
    required this.url,
    required this.fileName,
    required this.customHeaders,
    required this.retryAttempts,
    required this.parallelBatches,
    required this.subsUrl,
    required this.sendPort,
    required this.id,
    // required this.rootIsolateToken,
    required this.downloadPath,
    this.resumeFrom = 0, // next segment index if stream, exact progress if mp4
  });
}

class DownloadMessage {
  final int progress;
  final String status;
  final int id;
  final String? message;
  final List<Object> extras;

  DownloadMessage({
    required this.status,
    required this.id,
    this.message,
    this.progress = 0,
    this.extras = const [],
  });
}

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
      status: getDownloadStatus(map['status']),
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

class BufferItem {
  final int index;
  final Uint8List buffer;

  BufferItem({required this.index, required this.buffer});
}
