import 'dart:isolate';
import 'dart:ui';

import 'package:animestream/core/app/logging.dart';
import 'package:animestream/core/commons/extensions.dart';
import 'package:collection/collection.dart';

import 'package:animestream/core/anime/downloader/downloadManager.dart';
import 'package:animestream/core/anime/downloader/downloaderCore.dart';
import 'package:animestream/core/anime/downloader/downloaderHelper.dart';
import 'package:animestream/core/anime/downloader/types.dart';
import 'package:animestream/core/app/runtimeDatas.dart';

enum _DownloadType { stream, video, image }

/// Manages the downloads, Isolates, Queueing
class Downloader {
  final DownloaderHelper _helper = DownloaderHelper();

  static final Map<int, Isolate> _isolates = {};

  static final Map<int, ReceivePort> _receivePorts = {};

  /// Ports to send command to isolates
  static final Map<int, SendPort> _isolatePorts = {};

  /// The max concurrent downloads count
  static const int MAX_DOWNLOADS_COUNT = 5;

  /// The max batch size per stream (for segments)
  static int MAX_STREAM_BATCH_SIZE = 5;

  /// Count of Refetching failed segments
  static int MAX_RETRY_ATTEMPTS = 5;

  Future<void> startDownload(DownloadItem item) async {
    // add the item to queue and wait for it to be processed
    DownloadManager.enqueue(item);

    _processQueue();
  }

  // The heart of this class
  Future<void> _processQueue() async {
    final isFull = DownloadManager.downloadsCount.value >= MAX_DOWNLOADS_COUNT;

    if (isFull) return; // ignore download request if batch is full

    if (currentUserSettings?.useQueuedDownloads ?? false) {
      // Pick next queued item and dont do anything if none left!
      final item = DownloadManager.downloadingItems.firstWhereOrNull((it) => it.status == DownloadStatus.queued);
      if (item == null) return;

      // Dont download if active item is present
      if (DownloadManager.downloadingItems.any((it) => it.status == DownloadStatus.downloading)) return;
      item.status = DownloadStatus.downloading;
      await _fireUpIsolate(item);
    } else {
      // Download items till tummy is filled (MAX_COUNT reached)
      while (DownloadManager.downloadsCount.value < MAX_DOWNLOADS_COUNT) {
        final next = DownloadManager.downloadingItems.firstWhereOrNull((it) => it.isQueued);
        if (next == null) break;
        next.status = DownloadStatus.downloading;
        await _fireUpIsolate(next);
      }
    }
  }

  Future<void> _fireUpIsolate(DownloadItem item) async {
    final task = _cookTask(item);
    Future<void> Function(DownloadTaskIsolate) downloadFunction;

    final type = await _getDownloadType(item);

    // Infer the type
    switch (type) {
      case _DownloadType.image:
        downloadFunction = DownloaderCore.downloadImage;
      case _DownloadType.video:
        downloadFunction = DownloaderCore.downloadVideo;
      case _DownloadType.stream:
        downloadFunction = DownloaderCore.downloadStream;
    }

    // Run the downloading
    final isolate = await Isolate.spawn(downloadFunction, task);
    _isolates[item.id] = isolate;
  }

  Future<void> _cleanUp(int id) async {
    // Close and remove isolate entry
    _isolates[id]?.kill(priority: Isolate.immediate); // NUKE THAT F-
    _isolates.remove(id);

    // Close and remove port entry
    _receivePorts[id]?.close();
    _receivePorts.remove(id);

    // Remove it from existence (list)
    DownloadManager.dequeue(id);
  }

  Future<void> requestCancellation(int id) async {
    _isolatePorts[id]?.send('cancel');
    // hmm thinking of doing this, but since cancellation is requested
    // and not really cancelled, should it be set as cancelled?
    // DownloadManager.downloadingItems.firstWhereOrNull((it) => it.id == id)?.status = DownloadStatus.cancelled;
  }

  Future<void> _handleMessage(dynamic msg) async {
    if (!(msg is DownloadMessage)) return;
    switch (msg.status) {
      // Stuff for download state
      case 'progress':
        {
          DownloadManager.downloadingItems.firstWhereOrNull((it) => it.id == msg.id)?.progress = msg.progress;
        }
      case 'complete':
        {
          _cleanUp(msg.id);
        }
      case 'error':
        {
          _cleanUp(msg.id);
          print("Welp, something went wrong..");
          await Logger()
            ..addLog("Download Manager: error on ${msg.id} ${msg.message}")
            ..writeLog();
        }
      case 'fail':
        {
          _cleanUp(msg.id);
          print("Download failed for ${msg.id}");
        }
      case 'cancel':
        {
          _cleanUp(msg.id);
          print("Download cancelled for ${msg.id}");
        }

      // Non download state stuff
      case 'port':
        {
          if (msg.extras.isNotEmpty && msg.extras.first is SendPort)
            _isolatePorts[msg.id] = msg.extras.first as SendPort;
        }

      default:
        {
          throw Exception("What the f*ck is ${msg.status} supposed to mean? (Unknown status exception)");
        }
    }
  }

  DownloadTaskIsolate _cookTask(DownloadItem item) {
    final rp = ReceivePort();

    rp.listen(_handleMessage);

    final rootIsolateToken = RootIsolateToken.instance!;

    _receivePorts[item.id]?.close(); // close if already exists (JIC)
    _receivePorts[item.id] = rp;

    final task = DownloadTaskIsolate(
      url: item.url,
      fileName: item.fileName,
      customHeaders: item.customHeaders,
      retryAttempts: MAX_RETRY_ATTEMPTS,
      parallelBatches: MAX_STREAM_BATCH_SIZE,
      subsUrl: item.subtitleUrl,
      sendPort: rp.sendPort,
      id: item.id,
      rootIsolateToken: rootIsolateToken,
    );

    return task;
  }

  Future<_DownloadType> _getDownloadType(DownloadItem item) async {
    final ext = _helper.extractVideoExtension(item.url);
    final videoExtensions = ['mp4', 'mkv', 'avi', 'webm', 'flv'];
    final streamExtensions = ['m3u8', 'm3u'];

    if ((videoExtensions + streamExtensions).contains(ext)) {
      if (videoExtensions.contains(ext)) return _DownloadType.video;
      if (streamExtensions.contains(ext)) return _DownloadType.stream;
      if (['webp', 'jpeg', 'jpg', 'png'].contains(ext)) return _DownloadType.image;
    }

    // Fallback (ik this is more precise, but dont wanna send a unnecessary request)
    final mime = await _helper.getMimeType(item.url, item.customHeaders);
    if (mime == null) throw Exception("Couldnt identify the media type.");
    if (mime.contains("mpegurl")) return _DownloadType.stream;
    if (mime.contains("video")) return _DownloadType.video;
    if (mime.contains("image")) return _DownloadType.image;

    throw Exception("The file of recieved format downloading isnt supported!");
  }
}
