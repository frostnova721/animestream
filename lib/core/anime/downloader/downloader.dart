import "dart:io";
import "package:animestream/core/anime/downloader/types.dart";
import "package:animestream/ui/models/notification.dart";
import "package:animestream/ui/models/snackBar.dart";
import "package:http/http.dart";
import "package:path_provider/path_provider.dart";
import "package:permission_handler/permission_handler.dart";
import "package:animestream/core/commons/utils.dart";
import 'package:device_info_plus/device_info_plus.dart';

List<DownloadingItem> downloadQueue = [];

class Downloader {
  // check for storage permission and request for permission if permission isnt granted
  Future<bool> checkPermission() async {
    final os = await DeviceInfoPlugin().androidInfo;
    final sdkVer = os.version.sdkInt;

    Permission access;

    if (sdkVer > 32) {
      access = await Permission.videos;
    } else {
      access = await Permission.storage;
    }

    final status = await access.status;

    if (status.isPermanentlyDenied) {
      return false;
    }

    if (status.isDenied) {
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
    downloadQueue.removeWhere((item) => item.id == id);
  }

  int generateId() {
    int maxId = downloadQueue.isNotEmpty ? downloadQueue.map((item) => item.id).reduce((a, b) => a > b ? a : b) : 0;
    return maxId + 1;
  }

  Future<void> downloadImage(String imageUrl, String fileName) async {
    final permission = await checkPermission();
    if (!permission) {
      showToast("Permission denied! Grant access to storage");
      throw Exception("Couldnt download image due to lack of permission!");
    }
    final downPath = await Directory('/storage/emulated/0/Download');
    String finalPath;
    final fileExtension = imageUrl.split('/').last.split(".").last.trim();
    fileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '');
    if (downPath.existsSync()) {
      final directory = Directory("${downPath.path}/animestream/");
      if (!(await directory.exists())) {
        await directory.create(recursive: true);
      }
      finalPath = '/storage/emulated/0/Download/animestream/${fileName}.${fileExtension}';
    } else {
      final externalStorage = await getExternalStorageDirectory();
      final directory = Directory("${externalStorage?.path}/animestream/");
      if (!(await directory.exists())) {
        await directory.create(recursive: true);
      }
      finalPath = "${externalStorage?.path}/animestream/${fileName}.${fileExtension}";
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

  Future<void> download(String streamLink, String fileName, {int retryAttempts = 3, int parallelBatches = 5}) async {
    final permission = await checkPermission();
    if (!permission) {
      throw new Exception("ERR_NO_STORAGE_PERMISSION");
    }
    final downPath = await Directory('/storage/emulated/0/Download');
    String finalPath;
    fileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '');
    if (downPath.existsSync()) {
      final directory = Directory("${downPath.path}/animestream/");
      if (!(await directory.exists())) {
        await directory.create(recursive: true);
      }
      finalPath = '/storage/emulated/0/Download/animestream/${fileName}.mp4';
    } else {
      final externalStorage = await getExternalStorageDirectory();
      final directory = Directory("${externalStorage?.path}/animestream/");
      if (!(await directory.exists())) {
        await directory.create(recursive: true);
      }
      finalPath = "${externalStorage?.path}/animestream/${fileName}.mp4";
    }

    final output = File(finalPath);
    final List<BufferItem> buffers = [];

    //generate an id for the downloading item and add it to the queue(list)
    final downloadId = generateId();
    downloadQueue.add(DownloadingItem(id: downloadId, downloading: true));
    final streamBaseLink = _makeBaseLink(streamLink);

    try {
      final List<String> segments = await _getSegments(streamLink);
      List<String> segmentsFiltered = [];
      segments.forEach(
        (element) {
          if (element.length != 0) segmentsFiltered.add(element);
        },
      );

      final parallelDownloadsBatchSize = parallelBatches;

      for (int i = 0; i < segmentsFiltered.length; i += parallelDownloadsBatchSize) {
        final downloading = downloadQueue.where((item) => item.id == downloadId).firstOrNull;

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
            buffers.add(BufferItem(index: segmentNumber, buffer: res.bodyBytes));
          } else
            throw new Exception("ERR_REQ_FAILED");
        });

        //wait till whole batch is downloaded
        await Future.wait(futures);
      }

      //sort the buffers
      buffers.sort((a,b) => a.index.compareTo(b.index));  

      //write the data after full download.
      final out = await output.openWrite();
      for (final buffer in buffers) {
        out.add(buffer.buffer);
      }

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

  //download the segment
  Future<Response> downloadSegment(String url) async {
    try {
      final res = await get(Uri.parse(url));
      return res;
    } catch (err) {
      throw Exception("Failed to download segment: $err");
    }
  }

  Future<Response> downloadSegmentWithRetries(String url, int totalAttempts) async {
    int currentAttempt = 0;
    while (currentAttempt < totalAttempts) {
      try {
        currentAttempt++;
        final res = await downloadSegment(url)
            .timeout(Duration(seconds: 30), onTimeout: () => throw Exception("FAILED DOWNLOAD ATTEMPT"));
        return res;
      } catch (err) {
        if (currentAttempt >= totalAttempts) {
          throw Exception("NUMBER OF DOWNLOAD ATTEMPTS EXCEEDED");
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
      }
    }
    return segments;
  }
}
