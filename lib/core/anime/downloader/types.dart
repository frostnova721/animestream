// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/material.dart';

// some of them here are just for names lol
enum DownloadStatus { downloading, queued, paused, completed, cancelled, failed }

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

class BufferItem {
  final int index;
  final Uint8List buffer;

  BufferItem({required this.index, required this.buffer});
}
