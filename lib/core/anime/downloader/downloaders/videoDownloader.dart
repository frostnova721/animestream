import 'dart:async';
import 'dart:io';

import 'package:animestream/core/anime/downloader/downloaders/baseDownloader.dart';
import 'package:animestream/core/anime/downloader/types.dart';
import 'package:http/http.dart';

class VideoDownloader extends BaseDownloader {
  VideoDownloader(DownloadTaskIsolate task) : super(task);

  @override
  Future<void> download() async {
    await setUpPorts(task);

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
        if (status == DownloadStatus.cancelled) {
          await subscription?.cancel();
          await sink.close();
          file.deleteSync();

          completer.complete();

          setCancelledStatus();
          return;
        } else if (status == DownloadStatus.paused) {
          subscription?.pause();

          setPausedStatus(progress, downloadedBytes, filepath);

          super.completer = Completer();
          try {
            timer = Timer(Duration(minutes: 1), () => super.completer?.completeError(Exception("Timeout!")));
            await super.completer!.future;
            subscription?.resume();
            super.completer = null;
            timer?.cancel();
            timer = null;
          } catch (err) {
            print("Isolate Timeout! Error: ${err.toString()}");
            print("Self destructing isolate...");
            super.completer = null;
            timer?.cancel();
            timer = null;
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
          updateProgress(progress, filepath);
          lastProgress = progress;
        }
      }, onDone: () async {
        await sink.close();
        print("[DOWNLOADER] succesfully written the file to disk");
        completer.complete();
        setCompletedStatus(filepath);
      }, onError: (err) async {
        print(err);
        print("From media url: ${task.url}");
        completer.completeError(err);
        await sink.close();
        await file.delete();
        setFailedStatus(err.toString());
      });

      return completer.future;
    } catch (err) {
      // same stuff as on error
      print(err);
      print("From media url: ${task.url}");
      await sink.close();
      await file.delete();
      setFailedStatus(err.toString());
    }
  }
}
