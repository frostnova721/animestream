import 'package:animestream/core/anime/downloader/downloader.dart';
import 'package:animestream/core/anime/downloader/downloaderHelper.dart';
import 'package:animestream/core/anime/downloader/types.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:flutter/widgets.dart';

/// Manages and Keeps track of downloads.
class DownloadManager {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  DownloadManager._internal();

  // The currently downloading items (includes queue)
  static final List<DownloadItem> _downloadingItems = [];

  // The count for UI updations
  static final ValueNotifier<int> downloadsCount = ValueNotifier(0);

  // Getter for public usage
  static List<DownloadItem> get downloadingItems => List.unmodifiable(_downloadingItems);

  final Downloader _downloader = Downloader();

  /// The queue is managed from [Downloader] class
  static void enqueue(DownloadItem item) {
    _downloadingItems.add(item);
    downloadsCount.value++;
    print(
        "Added item to queue. Items in queue: ${downloadsCount.value}. [queue mode: ${(currentUserSettings?.useQueuedDownloads ?? false)}]");
  }

  /// The queue is managed from [Downloader] class
  static void dequeue(int id) {
    _downloadingItems.removeWhere((it) => it.id == id);
    downloadsCount.value--;
  }

  Future<void> addDownloadTask(
    String url,
    String filename, {
    String? subtitleUrl,
    Map<String, String> customHeaders = const {},
  }) async {
    if(!(await DownloaderHelper().checkAndRequestPermission())) {
      floatingSnackBar("Provide storage access for downloading...");
      return;
    }
    final id = DownloaderHelper.generateId();

    final item = DownloadItem(
      id: id,
      url: url,
      status: DownloadStatus.queued, // Every download is queued before initialisation!
      fileName: filename,
      customHeaders: customHeaders,
      progress: 0,
      subtitleUrl: subtitleUrl,
    );

    await _downloader.startDownload(item);
  }

  /// ** All of the below commands to the downloader are fire and forget. **
  // How was that loading screen tip?

  void cancelDownload(int id) {
    _downloader.requestCancellation(id);
  }

  void pauseDownload(int id) {
    _downloader.requestPause(id);
  }

  void resumeDownload(int id) {
    _downloader.requestResume(id);
  }

  Future<void> retryDownload(int id) async {}
}
