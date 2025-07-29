import 'dart:io';
import 'dart:isolate';

import 'package:collection/collection.dart';

import 'package:animestream/core/anime/downloader/downloadManager.dart';
import 'package:animestream/core/anime/downloader/downloaderCore.dart';
import 'package:animestream/core/anime/downloader/downloaderHelper.dart';
import 'package:animestream/core/anime/downloader/types.dart';
import 'package:animestream/core/app/logging.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/extensions.dart';
import 'package:animestream/core/data/downloadHistory.dart';

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

  DownloadItem _getDownloadItem(int id) {
    final item = DownloadManager.downloadingItems.firstWhereOrNull((it) => it.id == id);
    if (item != null) return item;
    throw Exception("Couldnt find an item with given id!");
  }

  DownloadItem? _maybeGetDownloadItem(int id) => DownloadManager.downloadingItems.firstWhereOrNull((it) => it.id == id);

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
      // item.status = DownloadStatus.downloading; // this is set using message from isolate
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

    final path = await _helper.getDownloadsPath();

    final task = _cookTask(item, path);

    print('[DOWNLOADER] Queuing task $task');

    // Run the downloading
    final isolate = await Isolate.spawn(downloadFunction, task);
    _isolates[item.id] = isolate;
  }

  Future<void> _cleanUp(int id, {bool dequeue = true}) async {
    // Close and remove isolate entry
    _isolates[id]?.kill(priority: Isolate.immediate); // NUKE THAT F-
    _isolates.remove(id);

    // remove the entry of send port (why am i commenting like this...)
    _isolatePorts.remove(id);

    // Close and remove port entry
    _receivePorts[id]?.close();
    _receivePorts.remove(id);

    // Remove it from existence (list)
    if (dequeue) DownloadManager.dequeue(id);
  }

  Future<void> _endTask(int id) async {
    // Perform isolate kill
    await _cleanUp(id);

    // Continue next download if scheduled
    _processQueue();
  }

  Future<void> requestCancellation(int id) async {
    _isolatePorts[id]?.send('cancel');
    // hmm thinking of doing this, but since cancellation is requested
    // and not really cancelled, should it be set as cancelled?
    // DownloadManager.downloadingItems.firstWhereOrNull((it) => it.id == id)?.status = DownloadStatus.cancelled;
  }

  Future<void> requestPause(int id) async {
    _isolatePorts[id]?.send('pause');
  }

  Future<void> requestResume(int id) async {
    _resumeTask(id);
  }

  Future<void> _pauseTask(int id, int progress, int nextSegmentIndex, String filePath) async {
    final item = _getDownloadItem(id);
    item.status = DownloadStatus.paused;
    item.lastDownloadedPart = nextSegmentIndex == -1 ? null : nextSegmentIndex;
    // await DownloadHistory.saveItem(_cookHistoryItem(item, DownloadStatus.paused, filePath));
  }

  Future<void> _resumeTask(int id) async {
    if (_isolates[id] == null) {
      final item = _getDownloadItem(id);
      return _fireUpIsolate(item);
    } else {
      // This condition would mean that the isolate is alive, then js resume the downloads
      _isolatePorts[id]?.send('resume');
    }
  }

  Future<void> _retryDownload(int id) async {
    _cleanUp(id, dequeue: false);
    final item = _getDownloadItem(id);

    // Set the item to initial condition!
    item.progress = 0;
    item.status = DownloadStatus.downloading;
    item.lastDownloadedPart = null;

    _fireUpIsolate(item);
  }

  Future<void> _handleMessage(dynamic msg) async {
    if (!(msg is DownloadMessage)) {
      print("Recieved message. But not as DownloadMessage!\nMessage: $msg");
      return;
    }
    switch (msg.status) {
      // Stuff for download state
      case 'progress':
        {
          _maybeGetDownloadItem(msg.id)?.progress = msg.progress;
          _helper.sendProgressNotif(msg.id, msg.progress, msg.extras[0] as String, msg.extras[1] as String);
          break;
        }
      case 'downloading':
        _maybeGetDownloadItem(msg.id)?.status = DownloadStatus.downloading;
        break;

      case 'complete':
        {
          _helper.sendCompletedNotif(msg.id, msg.extras[0] as String, msg.extras[1] as String);
          DownloadHistory.saveItem(
              _cookHistoryItem(_getDownloadItem(msg.id), DownloadStatus.completed, msg.extras[1] as String));
          _endTask(msg.id);
          break;
        }
      case 'error':
        {
          _endTask(msg.id);
          print("Welp, something went wrong..");
          await Logger()
            ..addLog("Download Manager: error on ${msg.id} ${msg.message}")
            ..writeLog();
          break;
        }
      case 'fail':
        {
          _helper.sendCancelledNotif(msg.id, failed: true);
          _endTask(msg.id);
          print("Download failed for ${msg.id}. Reason: ${msg.message}");
          break;
        }
      case 'cancel':
        {
          _helper.sendCancelledNotif(msg.id, failed: false);
          _endTask(msg.id);

          print("Download cancelled for ${msg.id}");
          break;
        }
      case 'paused':
        _pauseTask(msg.id, msg.progress, msg.extras.first as int, msg.extras[1] as String);
        break;

      case 'retry':
        _retryDownload(msg.id);
        break;

      // Non download state stuff
      case 'port':
        if (msg.extras.isNotEmpty && msg.extras.first is SendPort) _isolatePorts[msg.id] = msg.extras.first as SendPort;
        break;

      case 'isolate_timeout':
        _cleanUp(msg.id, dequeue: false);
        break;

      default:
        {
          throw Exception("What the f*ck is ${msg.status} supposed to mean? (Unknown status exception)");
        }
    }
  }

  DownloadTaskIsolate _cookTask(DownloadItem item, String downloadPath) {
    final rp = ReceivePort();

    rp.listen(_handleMessage);

    // final rootIsolateToken = RootIsolateToken.instance!;

    _receivePorts[item.id]?.close(); // close if already exists (JIC)
    _receivePorts[item.id] = rp;

    final task = DownloadTaskIsolate(
      url: item.url,
      fileName: item.fileName,
      customHeaders: item.customHeaders,
      retryAttempts: MAX_RETRY_ATTEMPTS,
      parallelBatches: MAX_STREAM_BATCH_SIZE * ((currentUserSettings?.fasterDownloads ?? false ) ? 2 : 1 ),
      subsUrl: item.subtitleUrl,
      sendPort: rp.sendPort,
      id: item.id,
      // rootIsolateToken: rootIsolateToken,
      downloadPath: downloadPath,
      resumeFrom: item.lastDownloadedPart ?? 0,
    );

    return task;
  }

  DownloadHistoryItem _cookHistoryItem(DownloadItem item, DownloadStatus newStatus, String filepath) {
    int size;

    // CUS THIS MF CAN FAIL FOR SOME REASON EVEN THOUGH ITS KINDA RARE! (Fuck overheads)
    try {
      size = File(filepath).lengthSync();
    } catch(err) {
      size = 0;
    }

    return DownloadHistoryItem(
      id: item.id,
      status: newStatus,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      filePath: filepath,
      url: item.url,
      headers: item.customHeaders,
      fileName: item.fileName,
      size: size,
      lastDownloadedPart: item.lastDownloadedPart,
    );
  }

  Future<_DownloadType> _getDownloadType(DownloadItem item) async {
    final ext = _helper.extractExtension(item.url);
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
