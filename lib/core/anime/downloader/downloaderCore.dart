import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:animestream/core/anime/downloader/downloaderHelper.dart';
import 'package:animestream/core/anime/downloader/types.dart';
import 'package:http/http.dart';

// The class handling the core of downloading
class DownloaderCore {
  final helper = DownloaderHelper();

  // Static methods for isolate friendliness
  static Future<void> downloadStream(DownloadTaskIsolate task) => DownloaderCore()._downloadStream(task);
  static Future<void> downloadVideo(DownloadTaskIsolate task) => DownloaderCore()._downloadVideo(task);
  static Future<void> downloadImage(DownloadTaskIsolate task) => DownloaderCore()._downloadImage(task);

  // If the item is in this class, it's default state is definitely downloading
  DownloadStatus _status = DownloadStatus.downloading;

  Future<void> _downloadStream(DownloadTaskIsolate task) async {

    _setUpPorts(task);

    final finalPath =
        await helper.makeDirectory(fileName: task.fileName, fileExtension: "mp4", downloadPath: task.downloadPath);

    // Download subtitles if available
    if (task.subsUrl != null) downloadSubs(task.subsUrl!, task.fileName, task.downloadPath);

    final output = File(finalPath);

    // open the write mode
    final out = await output.openWrite();

    try {
      final streamBaseLink = helper.makeBaseLink(task.url);
      final List<String> segments = await helper.getSegments(task.url, customHeaders: task.customHeaders);
      final Map<int, String> segmentsFiltered = {};

      // For efficient index retrieval
      for (int i = 0; i < segments.length; i++) {
        if (segments[i].isNotEmpty) segmentsFiltered[i] = segments[i];
      }

      final entries = segmentsFiltered.entries.toList();

      final parallelDownloadsBatchSize = task.parallelBatches;

      int lastUpdatedProgress = 0; // Dont notify if progress is same

      for (int i = 0; i < segmentsFiltered.length; i += parallelDownloadsBatchSize) {
        final List<BufferItem> buffers = [];

        // calculate batch's length
        final batchEnd = (i + parallelDownloadsBatchSize < segmentsFiltered.length)
            ? i + parallelDownloadsBatchSize
            : segmentsFiltered.length;

        final batch = entries.sublist(i, batchEnd);

        print("[DOWNLOADER]<${task.id}> fetching segments [$i-$batchEnd of ${entries.length - 1}]");

        final futures = batch.map((entry) async {
          if (_status == DownloadStatus.cancelled) {
            return;
          }

          final segment = entry.value;
          final segmentNumber = entry.key + 1;

          final uri = segment.startsWith('http') ? segment : "$streamBaseLink/$segment";

          final progress = ((segmentNumber / entries.length) * 100).toInt();

          if (progress > lastUpdatedProgress) {
            // Update download progress thru the notification
            task.sendPort?.send(DownloadMessage(
                status: 'progress', progress: progress, extras: [finalPath], message: "progressing...", id: task.id));

            lastUpdatedProgress = progress;
          }

          final res =
              await helper.downloadSegmentWithRetries(uri, task.retryAttempts, customHeaders: task.customHeaders);

          if (res.statusCode >= 200 && res.statusCode < 300) {
            // Decrypt if theres an encryption
            if (helper.encryptionKey != null) {
              buffers.add(BufferItem(index: segmentNumber, buffer: helper.decryptSegment(res.bodyBytes)));
            } else {
              buffers.add(BufferItem(index: segmentNumber, buffer: res.bodyBytes));
            }
          } else
            throw new Exception("ERR_REQ_FAILED. Status: ${res.statusCode} for segment: $segment");
        });

        //wait till whole batch is downloaded
        await Future.wait(futures);

        // Beak the downloading if cancelled
        if (_status == DownloadStatus.cancelled) {
          buffers.clear();
          break;
        }

        //sort the buffers
        buffers.sort((a, b) => a.index.compareTo(b.index));

        // Write the downloaded buffers
        for (final b in buffers) out.add(b.buffer);
      }

      // send the completion/cancelled notification
      if (_status == DownloadStatus.cancelled) {
        await out.close();
        await output.delete();
        task.sendPort
            ?.send(DownloadMessage(status: 'cancel', id: task.id, message: "Download cancelled on user request"));
      } else {
        // Assume completion since fail, cancelled are handled already
        _status = DownloadStatus.completed;
        await out.close();
        task.sendPort?.send(
            DownloadMessage(status: 'complete', extras: [finalPath], message: "Download complete.", id: task.id));
      }

      print("[DOWNLOADER]<${task.id}> Closing download with state: ${_status.name}");
    } catch (err) {
      print(err);

      await out.close();
      if (await output.exists()) output.delete();

      //send download failed notification
      task.sendPort?.send(DownloadMessage(status: 'fail', message: "Download failed.", id: task.id));
    }
  }

  /// Download a mp4 video
  Future<void> _downloadVideo(DownloadTaskIsolate task) async {
    _setUpPorts(task);

    // Guess/Extract extension from link, otherwise give null and download as an mp4
    String? extensionGuess = helper.extractExtension(task.url);
    extensionGuess = ['mp4', 'mkv', 'avi', 'webm', 'flv'].contains(extensionGuess) ? extensionGuess : null;

    final filepath = await helper.makeDirectory(
      fileName: task.fileName,
      fileExtension: extensionGuess,
      downloadPath: task.downloadPath,
    );

    //we considering the file as mp4
    final req = Request("GET", Uri.parse(task.url));
    // add the headers
    req.headers.addAll(task.customHeaders);

    final file = File(filepath);
    final sink = file.openWrite();

    // just to catch any OS errors like file access
    try {
      final res = await req.send();
      if (!(res.statusCode >= 200 && res.statusCode < 300)) {
        throw Exception("Received response with status code ${res.statusCode}");
      }
      final totalSize = res.contentLength ?? -1;
      int downloadedBytes = 0;
      int lastProgress = 0;
      int lastPrintedProgress = 0; // to reduce console logs.

      StreamSubscription<List<int>>? subscription;

      final completer = Completer<void>();

      subscription = res.stream.listen((chunk) async {
        if (_status == DownloadStatus.cancelled) {
          await subscription?.cancel();
          await sink.close();
          file.deleteSync();

          completer.complete();
          task.sendPort?.send(DownloadMessage(
            status: 'cancel',
            id: task.id,
          ));
          return;
        }

        sink.add(chunk);
        downloadedBytes += chunk.length;

        final progress = (downloadedBytes / totalSize * 100).toInt();

        if (progress > lastProgress) {
          // just to reduce the logging from 100 to 10
          if (progress >= lastPrintedProgress) {
            print("[DOWNLOADER]<${task.id}> Progress: ${progress}%");
            lastPrintedProgress += 10;
          }

          task.sendPort?.send(DownloadMessage(status: 'progress', progress: progress, extras: [filepath], id: task.id));
          lastProgress = progress;
        }
      }, onDone: () async {
        await sink.close();
        print("[DOWNLOADER] succesfully written the file to disk");
        completer.complete();
        task.sendPort?.send(DownloadMessage(status: 'complete', extras: [filepath], id: task.id));
      }, onError: (err) async {
        print(err);
        print("From media url: ${task.url}");
        completer.completeError(err);
        await sink.close();
        await file.delete();
        task.sendPort?.send(DownloadMessage(status: 'fail', id: task.id, message: "Download failed!"));
      });

      return completer.future;
    } catch (err) {
      // same stuff as on error
      print(err);
      print("From media url: ${task.url}");
      await sink.close();
      await file.delete();
      task.sendPort?.send(DownloadMessage(status: 'fail', id: task.id, message: "Download failed!"));
    }
  }

  /// Download an Image
  Future<void> _downloadImage(DownloadTaskIsolate task) async {
    try {
      final ext = helper.extractExtension(task.url);
      final fileName = task.fileName.substring(
          0, task.fileName.length - "-Banner".length); // jst to remove the 'banner' suffix from anime_name-banner
      final outDir = await helper.makeDirectory(
        fileName: fileName,
        isImage: true,
        fileExtension: ext,
        downloadPath: task.downloadPath,
      );
      final out = File(outDir);
      final imgData = (await get(Uri.parse(task.url))).bodyBytes;
      await out.writeAsBytes(imgData);

      print("Saved image to ${out.path}");
    } catch (err) {
      throw Exception("Couldnt download image. $err");
    }
  }

  Future<void> downloadSubs(String url, String fileName, String downloadPath) async {
    final path = await helper.makeDirectory(
      fileName: fileName + "_subs",
      fileExtension: url.split(".").lastOrNull ?? "txt",
      downloadPath: downloadPath,
    );
    final file = File(path);
    await file.writeAsString((await get(Uri.parse(url))).body);
    return;
  }

  Future<void> _setUpPorts(DownloadTaskIsolate task) async {
    final rp = ReceivePort();
    task.sendPort?.send(DownloadMessage(status: 'port', id: task.id, extras: [rp.sendPort]));

    rp.listen((msg) {
      if (msg is String) {
        switch (msg) {
          case 'cancel':
            {
              _status = DownloadStatus.cancelled;
              print("Set download status of ${task.id} to ${_status.name}.");
            }
          default:
            {
              print("Recieved undefined command $msg for isolate ${task.id}. Ignoring...");
            }
        }
      }
    });
  }
}
