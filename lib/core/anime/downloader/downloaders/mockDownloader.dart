import 'dart:async';
import 'dart:io';

import 'package:animestream/core/anime/downloader/downloaders/baseDownloader.dart';
import 'package:animestream/core/anime/downloader/types.dart';

class MockDownloader extends BaseDownloader {
  MockDownloader(DownloadTaskIsolate task) : super(task);

  @override
  Future<void> download() async {
    await setUpPorts(task);

    final finalPath =
        await helper.makeDirectory(fileName: task.fileName, fileExtension: 'mp4', downloadPath: task.downloadPath);

    int progress = task.resumeFrom.clamp(0, 100);
    if (progress > 0) {
      updateProgress(progress, finalPath);
    }

    while (progress < 100) {
      if (status == DownloadStatus.cancelled) {
        final file = File(finalPath);
        if (await file.exists()) {
          await file.delete();
        }
        setCancelledStatus();
        return;
      }

      if (status == DownloadStatus.paused) {
        setPausedStatus(progress, progress, finalPath);

        completer = Completer<void>();
        try {
          timer = Timer(const Duration(minutes: 1), () => completer?.completeError(Exception('Timeout!')));
          await completer!.future;
          completer = null;
          timer?.cancel();
          timer = null;
        } catch (err) {
          print('Mock downloader isolate timeout: ${err.toString()}');
          completer = null;
          timer?.cancel();
          timer = null;
          task.sendPort?.send(DownloadMessage(status: 'isolate_timeout', id: task.id));
          return;
        }
      }

      await Future.delayed(const Duration(milliseconds: 120));
      progress += 2;
      if (progress > 100) progress = 100;
      updateProgress(progress, finalPath);
    }

    final file = File(finalPath);
    await file.writeAsString(
      'Mock download generated for development testing.\n'
      'File: ${task.fileName}\n'
      'Source: ${task.url}\n'
      'Timestamp: ${DateTime.now().toIso8601String()}\n',
    );

    setCompletedStatus(finalPath);
  }

  @override
  Future<void> onCancel() async {
    return;
  }
}