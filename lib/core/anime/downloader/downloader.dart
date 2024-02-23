import "dart:io";
import "package:http/http.dart";
import "package:path_provider/path_provider.dart";
import "../../commons/utils.dart";

class Downloader {
  String _makeBaseLink(String uri) {
    final split = uri.split('/');
    split.removeLast();
    return split.join('/');
  }

  Future<void> download(String streamLink, String fileName) async {
    final downPath = await Directory('/storage/emulated/0/Download');
    String finalPath;
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
    var out = output.openWrite();
    final streamBaseLink = _makeBaseLink(streamLink);
    try {
      final List<String> segments = await _getSegments(streamLink);
      for (final segment in segments) {
        if (segment.length != 0) {
          final uri =
              segment.startsWith('http') ? segment : "$streamBaseLink/$segment";
          print("fetching segment [${segment.indexOf(segment)}/${segments.length}]");
          final res = await get(Uri.parse(uri));
          if (res.statusCode == 200) {
            out.add(res.bodyBytes);
          }
        }
      }
      await out.close();
    } catch (err) {
      print(err);
      await out.close();
      await output.delete();
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
