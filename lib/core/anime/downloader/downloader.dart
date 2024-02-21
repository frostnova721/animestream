import "dart:io";
import "package:http/http.dart";

import "../../commons/utils.dart";

class Downloader {
  String _makeBaseLink(String uri) {
    final split = uri.split('/');
    split.removeLast();
    return split.join('/');
  }

  Future<void> download(String streamLink, String fileName) async {
    final output = File(fileName);
    var out = output.openWrite();
    final streamBaseLink = _makeBaseLink(streamLink);
    try {
      final List<String> segments = await _getSegments(streamLink);
      for (final segment in segments) {
        if (segment.length != 0) {
          final uri =
              segment.startsWith('http') ? segment : "$streamBaseLink/$segment";
          print("fetching $segment");
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
