import "dart:io";
import "dart:typed_data";
import "package:animestream/ui/models/notification.dart";
import "package:http/http.dart";
import "package:path_provider/path_provider.dart";
import "../../commons/utils.dart";

bool downloading = false;

class Downloader {
  String _makeBaseLink(String uri) {
    final split = uri.split('/');
    split.removeLast();
    return split.join('/');
  }

  void cancelDownload() {
    downloading = false;
  }

  Future<void> download(String streamLink, String fileName) async {
    final downPath = await Directory('/storage/emulated/0/Download');
    String finalPath;
    fileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '');
    downloading = true;
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
    final List<Uint8List> buffers = [];
    // var out = output.openWrite();
    final streamBaseLink = _makeBaseLink(streamLink);
    try {
      final List<String> segments = await _getSegments(streamLink);
      List<String> segmentsFiltered = [];
      segments.forEach(
        (element) {
          if (element.length != 0) segmentsFiltered.add(element);
        },
      );
      for (final segment in segmentsFiltered) {
        if (!downloading) {
          await NotificationService().pushBasicNotification(
              "Download Cancelled", "The download has been cancelled.");
          downloading = false;
          buffers.clear();
          // await out.close();
          // await output.delete();
          return;
        }
        await Future.delayed(Duration(milliseconds: 50));
        if (segment.length != 0) {
          final uri =
              segment.startsWith('http') ? segment : "$streamBaseLink/$segment";
          final segmentNumber = segments.indexOf(segment) + 1;
          print("fetching segment [$segmentNumber/${segments.length}]");
          final res = await get(Uri.parse(uri));
          NotificationService().updateNotificationProgressBar(
              id: 69,
              currentStep: segmentNumber,
              maxStep: segments.length - 1,
              fileName: "$fileName.mp4",
              path: finalPath);
          if (res.statusCode == 200) {
            buffers.add(res.bodyBytes);
          } else
            throw new Exception("ERR_REQ_FAILED");
        }
      }
      //write the data after full download. (idk why)
      //un comment the commented lines to make it write the data to file as soon as it is downloaded
      final out = await output.openWrite();
      for (final buffer in buffers) {
        out.add(buffer);
      }
      await out.close();
    } catch (err) {
      print(err);
      await NotificationService().pushBasicNotification(
          "Download failed", "The download has been cancelled.");
      downloading = false;
      buffers.clear();
      if (await output.exists()) output.delete();
      // await out.close();
      // await output.delete();
    }
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
