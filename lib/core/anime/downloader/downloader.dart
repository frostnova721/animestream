import "dart:async";
import "dart:collection";
import "dart:io";
import "dart:typed_data";

import "package:encrypt/encrypt.dart";
import "package:http/http.dart";
import "package:path_provider/path_provider.dart";
import "package:permission_handler/permission_handler.dart";
import 'package:device_info_plus/device_info_plus.dart';

import "package:animestream/core/anime/downloader/types.dart";
import "package:animestream/core/app/runtimeDatas.dart";
import "package:animestream/core/commons/utils.dart";
import "package:animestream/ui/models/notification.dart";
import "package:animestream/ui/models/snackBar.dart";

class Downloader {
  //list of downloading items
  static List<DownloadingItem> downloadItems = [];

  // check for storage permission and request for permission if permission isnt granted
  Future<bool> checkPermission() async {
    if (Platform.isWindows) return true;
    final os = await DeviceInfoPlugin().androidInfo;
    final sdkVer = os.version.sdkInt;

    Permission access;

    if (sdkVer > 32) {
      access = await Permission.manageExternalStorage;
    } else {
      access = await Permission.storage;
    }

    final status = await access.status;

    if (status.isPermanentlyDenied) {
      return false;
    }

    if (status.isDenied) {
      showToast("Provide storage access to perform downloading, unneeded for default path!");
      final req = await access.request();
      if (req.isGranted) {
        return true;
      } else {
        return false;
      }
    } else {
      return true;
    }
  }

  String _makeBaseLink(String uri) {
    final split = uri.split('/');
    split.removeLast();
    return split.join('/');
  }

  void cancelDownload(int id) {
    Downloader.downloadItems.removeWhere((item) => item.id == id);
  }

  int generateId() {
    int maxId = Downloader.downloadItems.isNotEmpty
        ? Downloader.downloadItems.map((item) => item.id).reduce((a, b) => a > b ? a : b)
        : 0;
    return maxId + 1;
  }

  Future<void> downloadImage(String imageUrl, String fileName) async {
    final permission = await checkPermission();
    if (!permission) {
      showToast("Permission denied! Grant access to storage");
      throw Exception("Couldnt download image due to lack of permission!");
    }

    final basePath = currentUserSettings?.downloadPath ?? '/storage/emulated/0/Download/animestream';
    final downPath = await Directory(basePath);

    String finalPath;

    final fileExtension = imageUrl.split('/').last.split(".").last.trim();
    fileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '');

    if (downPath.existsSync()) {
      final directory = Directory("${downPath.path}/");
      if (!(await directory.exists())) {
        await directory.create(recursive: true);
      }

      finalPath = '${downPath.path}/${fileName}.${fileExtension}';
    } else {
      final externalStorage = await getExternalStorageDirectory();
      final directory = Directory("${externalStorage?.path}/");
      if (!(await directory.exists())) {
        await directory.create(recursive: true);
      }

      finalPath = "${externalStorage?.path}/${fileName}.${fileExtension}";
    }
    try {
      final out = File(finalPath);

      final imageData = (await get(Uri.parse(imageUrl))).bodyBytes;
      await out.writeAsBytes(imageData);

      print("saved to ${out.path}");
      return;
    } catch (err) {
      throw Exception("Couldnt download image. Reason: Something went wrong!");
    }
  }

  Future<void> download(String streamLink, String fileName, {int retryAttempts = 5, int parallelBatches = 5}) async {
    final permission = await checkPermission();
    if (!permission) {
      throw new Exception("ERR_NO_STORAGE_PERMISSION");
    }

    final basePath = currentUserSettings?.downloadPath ?? '/storage/emulated/0/Download/animestream';

    final downPath = await Directory(basePath);
    String finalPath;

    fileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '');

    if (downPath.existsSync()) {
      final directory = Directory("${downPath.path}/");
      if (!(await directory.exists())) {
        await directory.create(recursive: true);
      }

      finalPath = '$basePath/${fileName}.mp4';
    } else {
      final externalStorage = await getExternalStorageDirectory();
      final directory = Directory("${externalStorage?.path}/");
      if (!(await directory.exists())) {
        await directory.create(recursive: true);
      }

      finalPath = "${externalStorage?.path}/${fileName}.mp4";
    }

    final output = File(finalPath);
    final List<BufferItem> buffers = [];

    //generate an id for the downloading item and add it to the queue(list)
    final downloadId = generateId();
    Downloader.downloadItems.add(DownloadingItem(id: downloadId, downloading: true));

    if (!streamLink.contains(".m3u8")) {
      return await downloadMp4(streamLink, finalPath, fileName, downloadId);
    }

    try {
      final streamBaseLink = _makeBaseLink(streamLink);
      final List<String> segments = await _getSegments(streamLink);
      List<String> segmentsFiltered = [];
      segments.forEach(
        (element) {
          if (element.length != 0) segmentsFiltered.add(element);
        },
      );

      final parallelDownloadsBatchSize = parallelBatches;

      for (int i = 0; i < segmentsFiltered.length; i += parallelDownloadsBatchSize) {
        final downloading = Downloader.downloadItems.where((item) => item.id == downloadId).firstOrNull;

        //send cancelled notification and clear the buffer
        if (downloading == null) {
          await NotificationService().pushBasicNotification(
            downloadId,
            "Download Cancelled",
            "The download ($fileName) has been cancelled.",
          );
          buffers.clear();
          return;
        }

        final batchEnd = (i + parallelDownloadsBatchSize < segmentsFiltered.length)
            ? i + parallelDownloadsBatchSize
            : segmentsFiltered.length;
        final batches = segmentsFiltered.sublist(i, batchEnd);

        final futures = batches.map((segment) async {
          final uri = segment.startsWith('http') ? segment : "$streamBaseLink/$segment";
          final segmentNumber = segments.indexOf(segment) + 1;
          print("[DOWNLOADER]<${downloadId}> fetching segment [$segmentNumber/${segments.length - 1}]");

          NotificationService().updateNotificationProgressBar(
            id: downloadId,
            currentStep: segmentNumber,
            maxStep: segments.length - 1,
            fileName: "$fileName.mp4",
            path: finalPath,
          );
          final res = await downloadSegmentWithRetries(uri, retryAttempts);
          if (res.statusCode == 200) {
            if (encryptionKey != null) {
              buffers.add(BufferItem(index: segmentNumber, buffer: decryptSegment(res.bodyBytes)));
            } else
              buffers.add(BufferItem(index: segmentNumber, buffer: res.bodyBytes));
          } else
            throw new Exception("ERR_REQ_FAILED");
        });

        //wait till whole batch is downloaded
        await Future.wait(futures);
      }

      //sort the buffers
      buffers.sort((a, b) => a.index.compareTo(b.index));

      print("[DOWNLOADER] writing file to disk...");

      //write the data after full download.
      final out = await output.openWrite();
      for (final buffer in buffers) {
        out.add(buffer.buffer);
      }
      print("[DOWNLOADER] succesfully written the file to disk");

      cancelDownload(downloadId); //remove the download from the active list

      await out.close();
    } catch (err) {
      print(err);

      //send download failed notification
      await NotificationService().pushBasicNotification(
        downloadId,
        "Download failed",
        "The download has been cancelled.",
      );
      cancelDownload(downloadId);
      buffers.clear();
      if (await output.exists()) output.delete();
    }
  }

  Future<void> downloadMp4(String link, String filepath, String fileName, int downloadId) async {
    //we considering the file as mp4
    final req = Request("GET", Uri.parse(link));
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

    subscription = res.stream.listen((chunk) {
      if (Downloader.downloadItems.where((it) => it.id == downloadId).firstOrNull == null) {
        subscription?.cancel();
        sink.close();
        file.deleteSync();
        NotificationService().pushBasicNotification(
          downloadId,
          "Download Cancelled",
          "The download ($fileName) has been cancelled.",
        );
        return;
      }
      sink.add(chunk);
      downloadedBytes += chunk.length;

      final progress = (downloadedBytes / totalSize * 100).toInt();

      if (progress > lastProgress) {
        print("[DOWNLOADER]<$downloadId> Progress: $progress%");

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
      cancelDownload(downloadId);
    }, onError: (err) {
      print(err);
      NotificationService()
          .pushBasicNotification(downloadId, "Download Failed", "Something went wrong while fetching the file.");
      cancelDownload(downloadId);
    });
  }

  //The enc key [im assuming AES for animepahe cus thats the only use case for this in this app rn]
  Uint8List? encryptionKey = null;

  //download the segment
  Future<Response> downloadSegment(String url) async {
    try {
      final res = await get(Uri.parse(url));
      return res;
    } catch (err) {
      throw Exception("Failed to download segment: $err");
    }
  }

  Uint8List decryptSegment(Uint8List buffer) {
    try {
      final encrypt = Encrypter(AES(Key(encryptionKey!), mode: AESMode.cbc));
      final decryptedBuffer = encrypt.decryptBytes(Encrypted(buffer), iv: IV.fromLength(16));
      return Uint8List.fromList(decryptedBuffer);
    } catch (err) {
      print("COULDNT DECRYPT A SEGMENT, KILLING THE DOWNLOAD");
      print(err.toString());
      rethrow;
    }
  }

  Future<Response> downloadSegmentWithRetries(String url, int totalAttempts) async {
    int currentAttempt = 0;
    while (currentAttempt < totalAttempts) {
      try {
        currentAttempt++;
        final res = await downloadSegment(url)
            .timeout(Duration(seconds: 10), onTimeout: () => throw Exception("FAILED DOWNLOAD ATTEMPT"));
        return res;
      } catch (err) {
        if (currentAttempt >= totalAttempts) {
          throw Exception("NUMBER OF DOWNLOAD ATTEMPTS EXCEEDED, KILLING THE DOWNLOADS");
        }
      }
    }
    throw Exception("THIS SHOULD'NT BE THROWN");
  }

  Future<List<String>> _getSegments(String url) async {
    final List<String> segments = [];
    final res = await fetch(url);
    final lines = res.split('\n');
    for (final line in lines) {
      if (!line.startsWith("#")) {
        if (line.contains("EXT")) continue;
        segments.add(line.trim());
      } else {
        //get the encryption key if it exists
        if (encryptionKey == null && line.startsWith("#EXT-X-KEY:METHOD=")) {
          final regex = RegExp(r'#EXT-X-KEY:METHOD=([^"]+),URI="([^"]+)"');
          final match = regex.firstMatch(line);
          if (match != null) {
            if (match.group(1) == null || match.group(2) == null) {
              print("[DOWNLOADER] COULDNT GET THE ENCRYPTION TYPE OR THE KEY");
              continue;
            }
            print("[DOWNLOADER] Found encryption: ${match.group(1)}");
            encryptionKey = (await get(Uri.parse(match.group(2)!))).bodyBytes;
          }
        }
      }
    }
    return segments;
  }
}
