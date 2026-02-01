import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:animestream/core/anime/downloader/downloaderHelper.dart';
import 'package:animestream/core/anime/downloader/types.dart';

class BaseDownloader {
  DownloadStatus _status = DownloadStatus.downloading;

  DownloaderHelper helper = DownloaderHelper();

  Completer? _completer;
  
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