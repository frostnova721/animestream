import 'dart:async';
import 'dart:io';

import 'package:animestream/core/anime/downloader/downloaders/baseDownloader.dart';
import 'package:animestream/core/anime/downloader/types.dart';
import 'package:animestream/core/commons/extensions.dart';
import 'package:http/http.dart';

class StreamDownloader extends BaseDownloader {
  StreamDownloader(DownloadTaskIsolate task) : super(task);

  @override
  Future<void> download() async {
    await super.setUpPorts(task);

    final finalPath =
        await helper.makeDirectory(fileName: task.fileName, fileExtension: "mp4", downloadPath: task.downloadPath);

    // Download subtitles if available
    if (task.subsUrl != null) downloadSubs(task.subsUrl!, task.fileName, finalPath);

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
        if (status == DownloadStatus.cancelled) {
          break; // just break out of the loop, the case is handled after loop close
        } else if (status == DownloadStatus.paused) {
          if (completer != null && !completer!.isCompleted) {
            print("Already waiting. Skipping duplicate pause.");
            return;
          }
          setPausedStatus(lastUpdatedProgress, lastDownloadedSegmentIndex, finalPath);
          completer = Completer();
          try {
            timer = Timer(Duration(minutes: 1), () => completer!.completeError(Exception("Isolate wait timeout")));
            await completer!.future;
            completer = null;
            timer?.cancel();
            timer = null; // Kill the timer if resumed within the 1 minute window
          } catch (err) {
            print("Isolate wait timed out! \nError: ${err.toString()}");
            print("Self destructing isolate...");
            timer?.cancel(); // some gracefulness ?
            timer = null;
            completer = null;
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
            updateProgress(progress, finalPath);

            lastUpdatedProgress = progress;
          }

          final res =
              await helper.downloadSegmentWithRetries(uri, task.retryAttempts, customHeaders: task.customHeaders);

          // Imo this is one of the best place to execute cancellation
          if (status == DownloadStatus.cancelled) {
            return false;
          }

          if (res.statusCode >= 200 && res.statusCode < 300) {
            // Decrypt if theres an encryption
            if (helper.encryptionKey != null) {
              buffers.add(BufferItem(index: segmentNumber, buffer: helper.decryptSegment(res.bodyBytes)));
            } else {
              buffers.add(BufferItem(index: segmentNumber, buffer: res.bodyBytes));
            }
          } else {
            print("Error for segment: $uri, body: ${res.body}, res head: ${res.headers}");
            throw new Exception("ERR_REQ_FAILED. Got Status: ${res.statusCode} for segment: $segmentNumber");
          }
        });

        //wait till whole batch is downloaded
        await Future.wait(futures);

        // Beak the downloading if cancelled
        if (status == DownloadStatus.cancelled) {
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
      if (status.isCancelled) {
        await out.close();
        await output.delete();
        super.setCancelledStatus();
      } else if (status.isPaused) {
      } // do nothing!
      else {
        super.setCompletedStatus(finalPath);
        await out.close();
      }

      print("[DOWNLOADER]<${task.id}> Closing download with state: ${status.name}");
    } catch (err) {
      print(err);

      await out.close();
      if (await output.exists()) output.delete();

      //send download failed notification
      setFailedStatus(err.toString());
    }
  }

  Future<void> downloadSubs(String url, String fileName, String downloadPath) async {
    try {
      final folder = File(downloadPath).parent;
      fileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '') + " Subtitles";

      final ext = url.split(".").lastOrNull ?? "txt";
      final file = File("${folder.path}/$fileName.$ext");
      await file.writeAsString((await get(Uri.parse(url))).body);
      return;
    } catch (err) {
      print("[DOWNLOADER] Failed to download $fileName subs!");
    }
  }
}
