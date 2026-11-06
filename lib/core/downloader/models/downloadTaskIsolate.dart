// For isolates
import 'dart:isolate';

import 'package:animestream/core/commons/hlsParser/audioStream.dart';
import 'package:animestream/core/commons/hlsParser/qualityStream.dart';

class DownloadTaskIsolate {
  final String fileName;
  final int id;
  final String downloadPath;

  final QualityStream? videoStream;
  final List<AudioStream> audioStreams;

  // primary URL as a fallback, maybe for files which arent videos...
  final String rawUrl;

  // Get the primary URL to download
  String get url => videoStream?.url ?? rawUrl;

  final String? subsUrl;
  final bool writeSubtitleTrackToVideo; // only for remuxed videos

  final Map<String, String> customHeaders;
  final int retryAttempts;
  final int parallelBatches;

  final SendPort? sendPort;
  final int resumeFrom;
  final bool useMkvRemuxer;

  DownloadTaskIsolate({
    required this.fileName,
    required this.customHeaders,
    required this.retryAttempts,
    required this.parallelBatches,
    required this.subsUrl,
    required this.sendPort,
    required this.id,
    required this.downloadPath,
    this.videoStream,
    this.audioStreams = const [],
    String? url,
    this.resumeFrom = 0, // next segment index if stream, exact progress if mp4
    this.useMkvRemuxer = false,
    this.writeSubtitleTrackToVideo = false,
  }) : rawUrl = url ?? videoStream?.url ?? '';

  @override
  String toString() {
    return 'DownloadTaskIsolate(\n'
        '  id: $id,\n'
        '  fileName: $fileName,\n'
        '  url: $url,\n'
        '  downloadPath: $downloadPath,\n'
        '  resumeFrom: $resumeFrom,\n'
        '  remux: $useMkvRemuxer,\n'
        '  writeSubtitleTrackToVideo: $writeSubtitleTrackToVideo,\n'
        '  subsUrl: $subsUrl,\n'
        '  parallelBatches: $parallelBatches,\n'
        '  retryAttempts: $retryAttempts,\n'
        '  customHeaders: $customHeaders,\n'
        '  sendPort: $sendPort,\n'
        '  videoStream: $videoStream,\n'
        '  audioStreams: $audioStreams,\n'
        ')';
  }
}