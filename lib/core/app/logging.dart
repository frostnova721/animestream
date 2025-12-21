import 'dart:io';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class Logs {
  // Logbook for different modules

  static final app = Logbook("APP"); // Overall
  static final player = Logbook("PLAYER"); // Player related
  static final downloader = Logbook("DOWNLOADER"); // downloader service

  /// Writes all logs to disk
  static Future<void> writeAllLogs() async {
    await app.writeLog();
    await player.writeLog();
    await downloader.writeLog();
  }
}

class Logbook {
  final String tag;
  Logbook(this.tag) {
    final now = DateTime.now();
    session = "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}_"
        "${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}";
  }

  late final String session;

  final List<String> _logBuffer = [];

  /// Logs a message to console and adds to buffer according to preferences
  ///
  /// [message] is the message to log.
  ///
  /// Optional parameter:
  /// * [addToBuffer] forces adding to buffer regardless of user settings
  void log(String message, {bool addToBuffer = false}) {
    if (addToBuffer || (currentUserSettings?.enableLogging ?? false)) {
      if (this._logBuffer.length > 500) {
        //keep log buffer size manageable
        this._logBuffer.removeAt(0);
      }
      _logBuffer.add("[$tag]: $message");
    }

    if (kDebugMode) {
      debugPrint("[$tag]: $message");
    }
  }

  /// Clears the current log buffer
  void clearLog() => _logBuffer.clear();

  /// Writes the current log buffer to disk and flushes the buffer
  Future<void> writeLog() async {
    try {
      //write the log to Documents folder
      final docs = await getApplicationDocumentsDirectory();
      final dir = await Directory('${docs.path}/logs/${tag.toLowerCase()}').create(recursive: true);

      final filePath = "${dir.path}/$session.txt";
      final file = File(filePath);
      final data = _logBuffer.join(' \n');

      // we using append mode since a previous write can flush the buffer, causing data loss
      await file.writeAsString(data, mode: FileMode.append);
      _logBuffer.clear();
    } catch (err) {
      print("Failed to write log: $err");
    }
  }
}
