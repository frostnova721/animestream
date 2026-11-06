import 'package:animestream/core/downloader/models/common.dart';
import 'package:animestream/core/commons/hlsParser/audioStream.dart';
import 'package:animestream/core/commons/hlsParser/qualityStream.dart';
import 'package:flutter/material.dart';

class DownloadItem {
  // The download ID
  final int id;

  final String _rawUrl;

  // The URL to the media to download (can be stream or video file)
  // No need to be provided if VideoStream is provided.
  String get url => videoStream?.url ?? _rawUrl;

  // File name to be saved as
  final String fileName;

  // Custom header for fetching (if any)
  final Map<String, String> customHeaders;

  // Subtitle url
  final String? subtitleUrl;

  // Value to resume from after pausing
  int? lastDownloadedPart;

  // The video stream to download (if any)
  final QualityStream? videoStream;

  // The audio streams to download (if any)
  final List<AudioStream> audioStreams;

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

  final bool mock;

  DownloadItem({
    required this.id,
    required DownloadStatus status,
    required this.fileName,
    this.customHeaders = const {},
    this.videoStream,
    this.audioStreams = const [],
    String? url,
    int progress = 0,
    this.subtitleUrl,
    this.lastDownloadedPart,
    this.mock = false,
  }) : _rawUrl = url ?? videoStream?.url ?? '',
       assert(
         videoStream != null || (url != null && url.isNotEmpty) || mock,
         "Either url or videoStream must be provided",
       ) {
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