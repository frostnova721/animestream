import 'dart:io';

import 'package:animestream/core/anime/downloader/downloaders/baseDownloader.dart';
import 'package:animestream/core/anime/downloader/types.dart';
import 'package:http/http.dart';

class ImageDownloader extends BaseDownloader {
  ImageDownloader(DownloadTaskIsolate task) : super(task);

  @override
  Future<void> download() async {
    try {
      final ext = helper.extractExtension(task.url);
      final fileName = task.fileName.substring(
          0, task.fileName.length - "-Banner".length); // jst to remove the 'banner' suffix from anime_name-banner
      final outDir = await helper.makeDirectory(
        fileName: fileName,
        isImage: true,
        fileExtension: ext,
        downloadPath: task.downloadPath,
      );
      final out = File(outDir);
      final imgData = (await get(Uri.parse(task.url))).bodyBytes;
      await out.writeAsBytes(imgData);

      print("Saved image to ${out.path}");
      setCompletedStatus(out.path, silent: true);
    } catch (err) {
      throw Exception("Couldnt download image. $err");
    }
  }
}
