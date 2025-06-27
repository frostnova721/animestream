// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';

// some of them here are just for names lol
enum DownloadStatus { downloading, queued, paused, completed, cancelled, failed }

class DownloadItem {
  // The download ID
  final int id;

  // The Download status
  DownloadStatus status;

  // The URL to the media to download (can be stream or video file)
  final String url;

  // File name to be saved as
  final String fileName;

  // Custom header for fetching (if any)
  final Map<String, String> customHeaders;

  // Subtitle url
  final String? subtitleUrl;

  // Notifier for UI updation
  final ValueNotifier<int> progressNotifier = ValueNotifier(0);

  int get progress => progressNotifier.value;

  set progress(int prg) {
    progressNotifier.value = prg;
  }

  DownloadItem({
    required this.id,
    required this.url,
    required this.status,
    required this.fileName,
    this.customHeaders = const {},
    int progress = 0,
    this.subtitleUrl,
  }) {
    progressNotifier.value = progress;
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
  final RootIsolateToken rootIsolateToken;

  DownloadTaskIsolate({
    required this.url,
    required this.fileName,
    required this.customHeaders,
    required this.retryAttempts,
    required this.parallelBatches,
    required this.subsUrl,
    required this.sendPort,
    required this.id,
    required this.rootIsolateToken,
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
