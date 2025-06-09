import 'dart:io';
import 'dart:typed_data';

import 'package:animestream/core/anime/downloader/downloader.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:encrypt/encrypt.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloaderHelper {
  // Requests for file permission.
  Future<bool> checkAndRequestPermission() async {
    // We have perm to store anywhere in windows ig
    if (Platform.isWindows) return true;

    Permission fileAccessPermission;

    final os = await DeviceInfoPlugin().androidInfo;
    final sdk = os.version.sdkInt;

    if (sdk > 32) {
      fileAccessPermission = await Permission.manageExternalStorage;
    } else {
      fileAccessPermission = await Permission.storage;
    }

    final status = await fileAccessPermission.status;

    if (status.isPermanentlyDenied) return false;

    if (status.isDenied) {
      showToast("Provide storage access for downloading!");
      final req = await fileAccessPermission.request();

      if (req.isGranted)
        return true;
      else
        return false;
    } else {
      return true;
    }
  }

  /// Generate id for the item
  int generateId() {
    int maxId = Downloader.downloadingItems.isNotEmpty
        ? Downloader.downloadingItems
            .map((item) => item.id) // get list of ids
            .reduce((a, b) => a > b ? a : b) // find the greatest number
        : 0;
    return maxId + 1;
  }

  /// Make the directory for the file
  Future<String> makeDirectory({required String fileName, bool isImage = false, String? fileExtension = null}) async {
    final basePath = currentUserSettings?.downloadPath ??
        (Platform.isWindows ? (await getDownloadsDirectory())!.path : '/storage/emulated/0/Download/animestream');

    final downPath = await Directory(basePath);
    String finalPath;

    fileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '');

    final ext = fileExtension ?? (isImage ? "png" : "mp4");

    // split the anime name
    final animeName = fileName.replaceAll(RegExp(r'\s+ep\s*\d+\s*$', caseSensitive: false), '').trim();

    if (downPath.existsSync()) {
      final directory = Directory("${downPath.path}/$animeName");
      if (!(await directory.exists())) {
        await directory.create(recursive: true);
      }

      finalPath = '$basePath/$animeName/$fileName.$ext';
    } else {
      final externalStorage = await getExternalStorageDirectory();
      final directory = Directory("${externalStorage?.path}/$animeName");
      if (!(await directory.exists())) {
        await directory.create(recursive: true);
      }

      finalPath = "${externalStorage?.path}/$animeName/$fileName.$ext";
    }

    return finalPath;
  }

  //The enc key [im assuming AES for animepahe cus thats the only use case for this in this app rn]
  Uint8List? encryptionKey = null;

  //download the segment
  Future<Response> downloadSegment(String url, {Map<String, String> customHeaders = const {}}) async {
    try {
      final res = await get(Uri.parse(url), headers: customHeaders);
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

  Future<Response> downloadSegmentWithRetries(String url, int totalAttempts, {Map<String, String> customHeaders = const {}}) async {
    int currentAttempt = 0;
    while (currentAttempt < totalAttempts) {
      try {
        currentAttempt++;
        final res = await downloadSegment(url, customHeaders: customHeaders)
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

  Future<List<String>> getSegments(String url, {Map<String, String> customHeaders = const {}}) async {
    final List<String> segments = [];
    final res = await get(Uri.parse(url), headers: customHeaders);
    final lines = res.body.split('\n');
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
            encryptionKey = (await get(Uri.parse(match.group(2)!), headers: customHeaders)).bodyBytes;
          }
        }
      }
    }
    return segments;
  }

  String makeBaseLink(String uri) {
    final split = uri.split('/');
    split.removeLast();
    return split.join('/');
  }

  Future<String?> getMimeType(String url, Map<String, String> headers) async {
  final client = HttpClient();
  try {
    final request = await client.headUrl(Uri.parse(url));
    headers.forEach((k,v) => request.headers.set(k, v));
    final res = await request.close();
    return res.headers.contentType?.mimeType;
  } finally {
    client.close();
  }
}
}
