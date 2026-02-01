import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:animestream/core/anime/downloader/downloaderHelper.dart';
import 'package:animestream/core/anime/downloader/types.dart';
import 'package:flutter/foundation.dart';

abstract class BaseDownloader {
  final DownloadTaskIsolate task;

  BaseDownloader(this.task);

  Future<void> download();

  /// If the item is in this class, it's default state is definitely downloading
  DownloadStatus _status = DownloadStatus.downloading;

  /// The current download state
  @nonVirtual
  DownloadStatus get status => _status;

  // @nonVirtual
  // set status(DownloadStatus newStatus) {
  //   this._status = newStatus;
  // }

  // The download helper instance ofcourse
  DownloaderHelper helper = DownloaderHelper();

  Completer? _completer;

  @nonVirtual
  Completer? get completer => _completer;

  @nonVirtual
  set completer(Completer? c) {
    _completer = c;
  }

  // Timer to kill the Isolate after pausing for n duration
  Timer? _timer;

  @nonVirtual
  Timer? get timer => _timer;

  @nonVirtual
  set timer(Timer? t) {
    _timer = t;
  }

  @nonVirtual
  void setPausedStatus(int progress, int resumeFrom, String filepath) {
    _status = DownloadStatus.paused;
    task.sendPort?.send(DownloadMessage(
      status: 'paused', id: task.id, message: "Paused at $progress%",
      extras: [resumeFrom, filepath], // Just pass which segment index it should resume from!
    ));
  }

  @nonVirtual
  void setCancelledStatus() {
    _status = DownloadStatus.cancelled;
    task.sendPort?.send(DownloadMessage(status: 'cancel', id: task.id, message: "Download cancelled on user request"));
  }

  @nonVirtual
  void setCompletedStatus(String finalPath) {
    _status = DownloadStatus.completed;
    task.sendPort?.send(DownloadMessage(
        status: 'complete', id: task.id, extras: [task.fileName, finalPath], message: "Download complete."));
  }

  @nonVirtual
  void setFailedStatus(String message) {
    _status = DownloadStatus.failed;
    task.sendPort?.send(DownloadMessage(status: 'fail', id: task.id, message: message));
  }

  @nonVirtual
  void updateProgress(int progress, String finalPath) {
    task.sendPort?.send(
        DownloadMessage(status: 'progress', id: task.id, progress: progress, extras: [task.fileName, finalPath]));
  }

  /// Set up the isolate ports for communicating with main thread.
  /// This method also sets up the listeners for commands from the [Downloader]
  /// and performs necessary changes to downloading states
  @nonVirtual
  Future<void> setUpPorts(DownloadTaskIsolate task) async {
    final rp = ReceivePort();
    task.sendPort?.send(DownloadMessage(status: 'port', id: task.id, extras: [rp.sendPort]));
    task.sendPort?.send(DownloadMessage(status: 'downloading', id: task.id)); // set as downloading!

    rp.listen((msg) async {
      if (msg is String) {
        switch (msg) {
          case 'cancel':
            {
              if (_status == DownloadStatus.paused) {
                final file = File(await helper.makeDirectory(fileName: task.fileName, downloadPath: task.downloadPath));
                if (await file.exists()) await file.delete();
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
