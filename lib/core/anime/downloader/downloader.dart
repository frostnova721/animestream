import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:animestream/core/anime/downloader/downloaderHelper.dart';
import 'package:animestream/core/anime/downloader/types.dart';
import 'package:animestream/ui/models/notification.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:http/http.dart';

class Downloader {
  // Actively downloading items
  static List<DownloadingItem> downloadingItems = [];

  // Queue of downloading items (for one by one downloads)
  static Queue<DownloadingItem> downloadQueue = Queue();

  DownloaderHelper helper = DownloaderHelper();

  // Cancel a download with its id
  void cancelDownload(int id) {
    Downloader.downloadingItems.removeWhere((item) => item.id == id);
    Downloader.downloadQueue.removeWhere((item) => item.id == id);
  }

  Future<void> downloadImage(String imageUrl, String fileName) async {
    final permission = await helper.checkAndRequestPermission();
    if (!permission) {
      showToast("Permission denied! Grant access to storage");
      throw Exception("Couldnt download image due to lack of permission!");
    }

    try {
      final ext = imageUrl.split('.').lastOrNull; // yeah usually
      fileName =
          fileName.substring(0, fileName.length - "-Banner".length); // jst to remove the banner from anime_name-banner
      final outDir = await helper.makeDirectory(fileName: fileName, isImage: true, fileExtension: ext);
      final out = File(outDir);
      final imgData = (await get(Uri.parse(imageUrl))).bodyBytes;
      await out.writeAsBytes(imgData);

      print("Saved image to ${out.path}");
    } catch (err) {
      throw Exception("Couldnt download image. $err");
    }
  }

  /// Add a download item to queue
  Future<void> addToQueue(
    String streamLink,
    String fileName, {
    int retryAttempts = 5,
    int parallelBatches = 5,
    Map<String, String> customHeaders = const {},
    String? subsUrl,
  }) async {
    final id = helper.generateId();
    final downloadItem = DownloadingItem(
      id: id,
      downloading: false,
      streamLink: streamLink,
      fileName: fileName,
      retryAttempts: retryAttempts,
      parallelBatches: parallelBatches,
      customHeaders: customHeaders,
      subtitleUrl: subsUrl,
    );

    downloadQueue.add(downloadItem);
    print("[DOWNLOADER] Added download $id to queue. Queue size: ${downloadQueue.length}");

    if (!downloadingItems.any((item) => item.downloading)) {
      _processQueue();
    }
  }

  /// download the items in queue
  Future<void> _processQueue() async {
    if (downloadQueue.isEmpty) return;

    // Pick the job from queue
    final item = downloadQueue.removeFirst();

    // Represent its downloading state
    downloadingItems.add(DownloadingItem(id: item.id, downloading: true));

    // Yep! downloading that mofo
    try {
      await download(item.streamLink!, item.fileName!,
          retryAttempts: item.retryAttempts,
          parallelBatches: item.parallelBatches,
          id: item.id,
          customHeaders: item.customHeaders,
          subsUrl: item.subtitleUrl);
    } catch (e) {
      print("[DOWNLOADER] Error processing download ${item.id}: $e");
    } finally {
      print("Cancelling");
      cancelDownload(item.id);

      // Process next item (if available)
      if (downloadQueue.isNotEmpty) {
        _processQueue();
      }
    }
  }

  Future<void> download(
    String streamLink,
    String fileName, {
    int retryAttempts = 5,
    int parallelBatches = 5,
    int? id = null,
    Map<String, String> customHeaders = const {},
    String? subsUrl,
  }) async {

    //generate an id for the downloading item and add it to the queue(list)
    int? downloadId = id;
    if (downloadId == null) {
      downloadId = helper.generateId();
      Downloader.downloadingItems.add(DownloadingItem(id: downloadId, downloading: true));
    }

    final permission = await helper.checkAndRequestPermission();
    if (!permission) {
      cancelDownload(downloadId);
      throw new Exception("ERR_NO_STORAGE_PERMISSION");
    }

    final finalPath = await helper.makeDirectory(fileName: fileName, fileExtension: "mp4");

    // Download subtitles if available
    if (subsUrl != null) downloadSubs(subsUrl, fileName);

    final output = File(finalPath);

    String? mime;

    if (!streamLink.contains(RegExp(r'\.(mp4|mkv|avi|webm|m3u8|m3u)', caseSensitive: false))) {
      mime = await helper.getMimeType(streamLink, customHeaders);
    }

    // Running on hopes n assumptions
    if ((mime != null && !mime.contains(RegExp(r'mpegurl', caseSensitive: false))) ||
        streamLink.contains(RegExp(r'\.(mp4|mkv|avi|webm)', caseSensitive: false))) {
      return await downloadMp4(streamLink, finalPath, fileName, downloadId, customHeaders: customHeaders);
    }

    print("Assuming its a stream!");

    // open the write mode
    final out = await output.openWrite();

    try {
      final streamBaseLink = helper.makeBaseLink(streamLink);
      final List<String> segments = await helper.getSegments(streamLink, customHeaders: customHeaders);
      List<String> segmentsFiltered = [];
      segments.forEach(
        (element) {
          if (element.length != 0) segmentsFiltered.add(element);
        },
      );

      final parallelDownloadsBatchSize = parallelBatches;

      for (int i = 0; i < segmentsFiltered.length; i += parallelDownloadsBatchSize) {
        final List<BufferItem> buffers = [];

        final downloading = Downloader.downloadingItems.where((item) => item.id == downloadId).firstOrNull;

        //send cancelled notification and delete the file
        if (downloading == null) {
          await NotificationService().pushBasicNotification(
            downloadId,
            "Download Cancelled",
            "The download ($fileName) has been cancelled.",
          );
          await out.close();
          await output.delete();
          return;
        }

        // calculate batch's length
        final batchEnd = (i + parallelDownloadsBatchSize < segmentsFiltered.length)
            ? i + parallelDownloadsBatchSize
            : segmentsFiltered.length;
        final batches = segmentsFiltered.sublist(i, batchEnd);

        print("[DOWNLOADER]<${downloadId}> fetching segments [$i-$batchEnd of ${segments.length - 1}]");

        final futures = batches.map((segment) async {
          final uri = segment.startsWith('http') ? segment : "$streamBaseLink/$segment";
          final segmentNumber = segments.indexOf(segment) + 1;

          // Update download progress thru the notification
          NotificationService().updateNotificationProgressBar(
            id: downloadId!,
            currentStep: segmentNumber,
            maxStep: segments.length - 1,
            fileName: "$fileName.mp4",
            path: finalPath,
          );

          final res = await helper.downloadSegmentWithRetries(uri, retryAttempts, customHeaders: customHeaders);

          if (res.statusCode == 200) {
            if (helper.encryptionKey != null) {
              buffers.add(BufferItem(index: segmentNumber, buffer: helper.decryptSegment(res.bodyBytes)));
            } else {
              buffers.add(BufferItem(index: segmentNumber, buffer: res.bodyBytes));
            }
          } else
            throw new Exception("ERR_REQ_FAILED");
        });

        //wait till whole batch is downloaded
        await Future.wait(futures);

        //sort the buffers
        buffers.sort((a, b) => a.index.compareTo(b.index));

        // Write the downloaded buffers
        for (final b in buffers) out.add(b.buffer);
      }

      print("[DOWNLOADER]<$downloadId> Download compelete!");

      // send the completion notification
      NotificationService().downloadCompletionNotification(
        id: downloadId,
        fileName: "$fileName.mp4",
        path: finalPath,
      );

      cancelDownload(downloadId); //remove the download from the active list

      await out.close();
    } catch (err) {
      print(err);

      //send download failed notification & cleanup
      await NotificationService().pushBasicNotification(
        downloadId,
        "Download failed",
        "The download has been cancelled.",
      );
      cancelDownload(downloadId);
      await out.close();
      if (await output.exists()) output.delete();
    }
  }

  Future<void> downloadMp4(String link, String filepath, String fileName, int downloadId,
      {Map<String, String> customHeaders = const {}}) async {
    //we considering the file as mp4
    final req = Request("GET", Uri.parse(link));
    // add the headers
    req.headers.addAll(customHeaders);
    final res = await req.send();
    if (res.statusCode != 200) {
      throw Exception("Received response with status code ${res.statusCode}");
    }
    final totalSize = res.contentLength ?? -1;
    int downloadedBytes = 0;
    final file = File(filepath);
    final sink = file.openWrite();
    int lastProgress = 0;

    StreamSubscription<List<int>>? subscription;

    final completer = Completer<void>();

    subscription = res.stream.listen((chunk) {
      if ((downloadingItems.where((it) => it.id == downloadId).firstOrNull) == null) {
        subscription?.cancel();
        sink.close();
        file.deleteSync();
        NotificationService().pushBasicNotification(
          downloadId,
          "Download Cancelled",
          "The download ($fileName) has been cancelled.",
        );
        return completer.complete();
      }
      sink.add(chunk);
      downloadedBytes += chunk.length;

      final progress = (downloadedBytes / totalSize * 100).toInt();

      if (progress > lastProgress) {
        print("[DOWNLOADER]<$downloadId> Progress: ${progress}%");

        NotificationService().updateNotificationProgressBar(
          id: downloadId,
          currentStep: progress,
          maxStep: 100,
          fileName: "$fileName.mp4",
          path: filepath,
        );
      }

      lastProgress = progress;
    }, onDone: () async {
      await sink.close();
      print("[DOWNLOADER] succesfully written the file to disk");
      NotificationService().downloadCompletionNotification(fileName: fileName, path: filepath, id: downloadId);
      cancelDownload(downloadId);
      completer.complete();
    }, onError: (err) {
      print(err);
      NotificationService()
          .pushBasicNotification(downloadId, "Download Failed", "Something went wrong while fetching the file.");
      cancelDownload(downloadId);
      completer.completeError(err);
    });

    return completer.future;
  }

  Future<void> downloadSubs(String url, String fileName) async {
    final path =
        await helper.makeDirectory(fileName: fileName + "_subs", fileExtension: url.split(".").lastOrNull ?? "txt");
    final file = File(path);
    await file.writeAsString((await get(Uri.parse(url))).body);
    return;
  }
}
