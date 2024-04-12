import 'package:animestream/core/commons/types.dart';
import 'package:animestream/core/commons/utils.dart';
import 'package:html/parser.dart';

class RyukExtractor {
  Future<List<Stream>> extract(String streamUrl) async {
    final res = await fetch(streamUrl);
    String streamLink = '';
    final doc = parse(res);
    doc.querySelectorAll("script").forEach((element) {
      final html = element.innerHtml;
      final regex = RegExp(r'"file":\s`(.*?)`');
      final match = regex.allMatches(html);
      if (match.isNotEmpty) {
        streamLink = match.firstOrNull?[1].toString() ?? '';
      }
    });
    if (streamLink.isEmpty) {
      throw new Exception("ERR_COULDNT_EXTRACT_RYUK_STREAM");
    }
    return [
      Stream(
        quality: "multi-quality",
        link: streamLink,
        isM3u8: streamLink.endsWith(".m3u8"),
        server: "ryuk",
        backup: false,
      )
    ];
  }
}
