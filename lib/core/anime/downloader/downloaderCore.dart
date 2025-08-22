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

  // Completer for managing paused state
  Completer<void>? _completer;

  // Timer to kill the Isolate after pausing for n duration
  Timer? _timer;

  Future<void> _downloadStream(DownloadTaskIsolate task) async {
    await _setUpPorts(task);

    final finalPath =
        await helper.makeDirectory(fileName: task.fileName, fileExtension: "mp4", downloadPath: task.downloadPath);

    // Download subtitles if available
    if (task.subsUrl != null) downloadSubs(task.subsUrl!, task.fileName, task.downloadPath);

    final output = File(finalPath);

    // open the write mode
    final out = await output.openWrite(mode: task.resumeFrom == 0 ? FileMode.write : FileMode.append);

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

      int lastDownloadedSegmentIndex = -1;

      for (int i = task.resumeFrom.toInt(); i < segmentsFiltered.length; i += parallelDownloadsBatchSize) {
        final List<BufferItem> buffers = [];

        // Handle commands
        if (_status == DownloadStatus.cancelled) {
          break; // just break out of the loop, the case is handled after loop close
        } else if (_status == DownloadStatus.paused) {
          if (_completer != null && !_completer!.isCompleted) {
            print("Already waiting. Skipping duplicate pause.");
            return;
          }
          task.sendPort?.send(DownloadMessage(
            status: 'paused',
            id: task.id,
            progress: lastUpdatedProgress,
            message: "Paused at $lastUpdatedProgress%",
            extras: [lastDownloadedSegmentIndex, finalPath], // Just pass which segment index it should resume from!
          ));

          _completer = Completer();
          try {
            _timer = Timer(Duration(minutes: 1), () => _completer!.completeError(Exception("Isolate wait timeout")));
            await _completer!.future;
            _completer = null;
            _timer?.cancel();
            _timer = null; // Kill the timer if resumed within the 1 minute window
          } catch (err) {
            print("Isolate wait timed out! \nError: ${err.toString()}");
            print("Self destructing isolate...");
            _timer?.cancel(); // some gracefulness ?
            _timer = null;
            _completer = null;
            task.sendPort?.send(DownloadMessage(status: 'isolate_timeout', id: task.id));
            break;
          }
        }

        // calculate batch's length
        final batchEnd = (i + parallelDownloadsBatchSize < segmentsFiltered.length)
            ? i + parallelDownloadsBatchSize
            : segmentsFiltered.length;

        final batch = entries.sublist(i, batchEnd);

        print("[DOWNLOADER]<${task.id}> fetching segments [$i-$batchEnd of ${entries.length}]");

        final futures = batch.map((entry) async {
          final segment = entry.value;
          final segmentNumber = entry.key + 1;

          final uri = segment.startsWith('http') ? segment : "$streamBaseLink/$segment";

          final progress = ((segmentNumber / entries.length) * 100).toInt();

          if (progress > lastUpdatedProgress) {
            // Update download progress thru the notification
            task.sendPort?.send(DownloadMessage(
                status: 'progress', progress: progress, extras: [task.fileName ,finalPath], message: "progressing...", id: task.id));

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

        // Start from next batch ig
        lastDownloadedSegmentIndex = i + parallelDownloadsBatchSize;
      }

      // send the completion/cancelled notification
      if (_status == DownloadStatus.cancelled) {
        await out.close();
        await output.delete();
        task.sendPort
            ?.send(DownloadMessage(status: 'cancel', id: task.id, message: "Download cancelled on user request"));
      } else if (_status == DownloadStatus.paused) {
      } // do nothing!
      else {
        _status = DownloadStatus.completed;
        await out.close();
        task.sendPort?.send(
            DownloadMessage(status: 'complete', extras: [task.fileName, finalPath], message: "Download complete.", id: task.id));
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
    await _setUpPorts(task);

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
    if (task.resumeFrom != 0) {
      final doesServerSupportRangeHeader = await helper.checkRangeSupport(Uri.parse(task.url));
      if (doesServerSupportRangeHeader) {
        req.headers.addAll({'Range': 'bytes=${task.resumeFrom}-'});
      } else {
        print("Server doesnt support ranges. Retrying download...");
        // start the download again
        task.sendPort?.send(DownloadMessage(status: 'retry', id: task.id));
        return;
      }
    }

    final file = File(filepath);

    final sink = file.openWrite(mode: task.resumeFrom == 0 ? FileMode.write : FileMode.append);

    // just to catch any OS errors like file access
    try {
      final res = await req.send();
      if (!(res.statusCode >= 200 && res.statusCode < 300)) {
        throw Exception("Received response with status code ${res.statusCode}");
      }
      final totalSize = res.contentLength ?? -1;
      int downloadedBytes = task.resumeFrom;
      int lastProgress = 0;
      int lastPrintedProgress = 0; // to reduce console logs.

      StreamSubscription<List<int>>? subscription;

      final completer = Completer<void>();

      subscription = res.stream.listen((chunk) async {
        // Write the data since its already fetched!
        sink.add(chunk);
        downloadedBytes += chunk.length;

        final progress = (downloadedBytes / totalSize * 100).toInt();

        // Handle commands
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
        } else if (_status == DownloadStatus.paused) {
          subscription?.pause();

          task.sendPort?.send(DownloadMessage(
            status: 'paused',
            id: task.id,
            progress: progress,
            message: "Paused at $progress%",
            extras: [downloadedBytes, filepath], // Just pass which segment index it should resume from!
          ));

          _completer = Completer();
          try {
            _timer = Timer(Duration(minutes: 1), () => _completer?.completeError(Exception("Timeout!")));
            await _completer!.future;
            subscription?.resume();
            _completer = null;
            _timer?.cancel();
            _timer = null;
          } catch (err) {
            print("Isolate Timeout! Error: ${err.toString()}");
            print("Self destructing isolate...");
            _completer = null;
            _timer?.cancel();
            _timer = null;
            subscription?.cancel();
            task.sendPort?.send(DownloadMessage(status: 'isolate_timeout', id: task.id));
          }
        }

        if (progress > lastProgress) {
          // just to reduce the logging from 100 to 10
          if (progress >= lastPrintedProgress) {
            print("[DOWNLOADER]<${task.id}> Progress: ${progress}%");
            lastPrintedProgress += 10;
          }

          task.sendPort?.send(DownloadMessage(status: 'progress', progress: progress, extras: [task.fileName ,filepath], id: task.id));
          lastProgress = progress;
        }
      }, onDone: () async {
        await sink.close();
        print("[DOWNLOADER] succesfully written the file to disk");
        completer.complete();
        task.sendPort?.send(DownloadMessage(status: 'complete', extras: [task.fileName, filepath], id: task.id));
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
      task.sendPort?.send(DownloadMessage(status: 'complete', id: task.id, silent: true));
    } catch (err) {
      throw Exception("Couldnt download image. $err");
    }
  }

  Future<void> downloadSubs(String url, String fileName, String downloadPath) async {
    try {
    final path = await helper.makeDirectory(
      fileName: fileName + "_subs",
      fileExtension: url.split(".").lastOrNull ?? "txt",
      downloadPath: downloadPath,
    );
    final file = File(path);
    await file.writeAsString((await get(Uri.parse(url))).body);
    return;
    } catch(err) {
      print("[DOWNLOADER] Failed to download $fileName subs!");
    }
  }

  Future<void> _setUpPorts(DownloadTaskIsolate task) async {
    final rp = ReceivePort();
    task.sendPort?.send(DownloadMessage(status: 'port', id: task.id, extras: [rp.sendPort]));
    task.sendPort?.send(DownloadMessage(status: 'downloading', id: task.id)); // set as downloading!

    rp.listen((msg) async {
      if (msg is String) {
        switch (msg) {
          case 'cancel':
            {
              if(_status == DownloadStatus.paused) {
                final file = File(await helper.makeDirectory(fileName: task.fileName, downloadPath: task.downloadPath));
                if(await file.exists()) await file.delete();
                print("[ISOLATE] Download Cancelled, Exiting Isolate");
                Isolate.exit(task.sendPort, DownloadMessage(status: "cancel", id: task.id));
              }
              _status = DownloadStatus.cancelled;
              break;
            }
          case 'pause':
            {
              _status = DownloadStatus.paused;
              break;
            }
          case 'resume':
            {
              _status = DownloadStatus.downloading;
              task.sendPort?.send(DownloadMessage(status: 'downloading', id: task.id));
              if (_completer != null && !_completer!.isCompleted) {
                _completer!.complete();
              }
            }
          default:
            {
              print("Recieved undefined command $msg for isolate ${task.id}. Ignoring...");
              return;
            }
        }
        // leave print msg here to avoid code duplication, cus now, this listener only
        // deals with altering the download states!
        print("Set download status of ${task.id} to ${_status.name}.");
      }
    });
  }
}
