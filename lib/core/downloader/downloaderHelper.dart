import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/app/notification.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class SegmentCancelledException implements Exception {}

class DownloaderHelper {
  static final _idSet = <int>{};

  final NotificationService _notifierService = NotificationService();

  // Requests for file permission.
  Future<bool> checkAndRequestPermission() async {
    // We have perm to store anywhere in windows n linux ig (not the root-ish paths ofc)
    if (Platform.isWindows || Platform.isLinux) return true;

    Permission fileAccessPermission;

    final os = await DeviceInfoPlugin().androidInfo;
    final sdk = os.version.sdkInt;

    if (sdk > 32) {
      fileAccessPermission = await Permission.manageExternalStorage;
    } else {
      fileAccessPermission = await Permission.storage;
    }

    final status = await fileAccessPermission.status;

    if (status.isPermanentlyDenied) {
      return false;
    }

    if (status.isDenied) {
      // showToast("Provide storage access for downloading!");
      return (await fileAccessPermission.request()).isGranted;
    } else {
      return true;
    }
  }

  // generate a unique id
  static int generateId() {
    int id = Random().nextInt(1 << 31); // rand 32 bit int
    while (_idSet.contains(id)) {
      id = Random().nextInt(1 << 31);
    }
    _idSet.add(id);
    return id;
  }

  Future<String> getDownloadsPath() async {
    String defDownloadPath; // just for windows

    if (currentUserSettings?.downloadPath != null) {
      return currentUserSettings!.downloadPath!;
    } else {
      try {
        defDownloadPath = (await getDownloadsDirectory())!.path;
      } catch (err) {
        // Default fallback
        defDownloadPath = '${Platform.environment['USERPROFILE']}\\Downloads';
      }
      return Platform.isWindows ? defDownloadPath : '/storage/emulated/0/Download/animestream';
    }
  }

  /// Make the directory for the file
  Future<String> makeDirectory({
    required String fileName,
    required downloadPath,
    bool isImage = false,
    String? fileExtension = null,
  }) async {
    final basePath = downloadPath;

    final downPath = await Directory(basePath);
    String finalPath;

    fileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '');

    final ext = fileExtension ?? (isImage ? "png" : "mp4");

    // split the anime name
    final animeName = fileName.replaceAll(RegExp(r'\s+ep\s*\d+\s*$', caseSensitive: false), '').trim();

    final sp = Platform.pathSeparator;

    // The check was BS since non existing directory cant be selected!
    final directory = Directory("${downPath.path}$sp$animeName");
    if (!(await directory.exists())) {
      await directory.create(recursive: true);
    }

    finalPath = '$basePath$sp$animeName$sp$fileName.$ext';
    return finalPath;
  }

  final _client = http.Client();

  /// Thrown when the download was cancelled on purpose; never retried.

  /// Downloads a segment. It's aborted if no bytes arrive for [idleTimeout], or when [cancel] completes.
  Future<http.Response> downloadSegment(
    String url, {
    Map<String, String> customHeaders = const {},
    Duration idleTimeout = const Duration(seconds: 10),
    Future<void>? cancel,
  }) async {
    final abort = Completer<void>();
    bool cancelled = false;
    void triggerAbort() {
      if (!abort.isCompleted) abort.complete();
    }

    cancel?.then((_) {
      cancelled = true;
      triggerAbort();
    });

    Timer? idle;
    void resetIdle() {
      idle?.cancel();
      idle = Timer(idleTimeout, triggerAbort);
    }

    final request = http.AbortableRequest('GET', Uri.parse(url), abortTrigger: abort.future)
      ..headers.addAll(customHeaders);

    try {
      resetIdle(); // covers connecting + waiting for headers
      final streamed = await _client.send(request);

      if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
        triggerAbort(); // don't bother downloading the error body
        throw http.ClientException("Segment download failed with status ${streamed.statusCode}", request.url);
      }

      final body = BytesBuilder(copy: false);
      await for (final chunk in streamed.stream) {
        resetIdle(); // still receiving data, so keep going however long it takes in total
        body.add(chunk);
      }
      return http.Response.bytes(body.takeBytes(), streamed.statusCode, headers: streamed.headers, request: request);
    } on http.RequestAbortedException {
      if (cancelled) throw SegmentCancelledException();
      throw TimeoutException("No data for ${idleTimeout.inSeconds}s", idleTimeout);
    } finally {
      idle?.cancel();
    }
  }

  Future<http.Response> downloadSegmentWithRetries(
    String url,
    int totalAttempts, {
    Map<String, String> customHeaders = const {},
    Future<void>? cancel,
  }) async {
    int currentAttempt = 0;
    while (currentAttempt < totalAttempts) {
      try {
        currentAttempt++;
        final res = await downloadSegment(
          url,
          customHeaders: customHeaders,
          cancel: cancel,
        );
        return res;
      } on SegmentCancelledException {
        rethrow;
      } catch (err) {
        if (currentAttempt >= totalAttempts) {
          throw Exception("NUMBER OF DOWNLOAD ATTEMPTS EXCEEDED, KILLING THE DOWNLOAD.");
        }
        // wait a second! let it breathe!
        await Future.delayed(Duration(seconds: 1));
      }
    }
    throw Exception("THIS SHOULD'NT BE THROWN");
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
      headers.forEach((k, v) => request.headers.set(k, v));
      final res = await request.close();
      return res.headers.contentType?.mimeType;
    } finally {
      client.close();
    }
  }

  // Small regex for getting usual extensions
  String? extractExtension(String url) {
    final match = RegExp(r'\.([a-zA-Z0-9]+)(?:\?|#|$)').firstMatch(url);
    if (match == null) return null;

    final ext = match.group(1)?.toLowerCase();

    return ext;
  }

  Future<bool> checkRangeSupport(Uri url, {Map<String, String> customHeaders = const {}}) async {
    final client = HttpClient();
    try {
      final req = await client.headUrl(url);
      customHeaders.forEach((k, v) {
        req.headers.add(k, v, preserveHeaderCase: true);
      });
      final res = await req.close();
      client.close();
      return res.headers.value('accept-ranges')?.toLowerCase() == "bytes";
    } catch (err) {
      client.close();
      return false;
    }
  }

  void sendProgressNotif(int id, int progress, String fileName, String downloadPath) {
    _notifierService.updateNotificationProgressBar(
      id: id,
      currentStep: progress,
      maxStep: 100,
      fileName: fileName,
      path: downloadPath,
    );
  }

  void sendCancelledNotif(int id, {bool failed = false}) {
    _notifierService.pushBasicNotification(
      id,
      "Download ${failed ? 'Failed' : 'Cancelled'}",
      "Download ${failed ? "failed due to an error. Check logs for details" : "was cancelled"}",
    );
  }

  void sendCompletedNotif(int id, String fileName, String downloadPath) {
    _notifierService.downloadCompletionNotification(id: id, fileName: fileName, path: downloadPath);
  }
}
