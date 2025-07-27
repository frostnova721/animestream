import 'package:animestream/core/anime/extractors/type.dart';
import 'package:animestream/core/anime/providers/types.dart';
import 'package:html/parser.dart' as html;
import 'package:js_unpack/js_unpack.dart';
import '../../commons/utils.dart';

class StreamWish extends AnimeExtractor {
  Future<List<VideoStream>> extract(String streamUrl, {String? label, Map<String, String>? headersOverrides}) async {
    if (streamUrl.isEmpty) {
      throw new Exception("ERROR: INVALID STREAM LINK");
    }

    final serverName = label ?? "streamwish";
    final res = await fetch(streamUrl);
    final doc = html.parse(res);
    String streamLink = '';
    String? subtitles;
    String unpackedData = "";
    doc.querySelectorAll('script').forEach((element) {
      if (streamLink.isEmpty) {
        try {
          final regex = RegExp(r'file:\s*"(.*?)"');
          final link = regex.allMatches(element.innerHtml);
          if (link.isNotEmpty) {
            unpackedData = element.innerHtml;
            // print(unpackedData);
            streamLink = link.firstOrNull?[1].toString() ?? '';
          } else {
            throw new Exception("WRONG FORMAT!");
          }
        } catch (err) {
          final regex = RegExp(r'eval\(function\(p,a,c,k,e,d\)');
          final html = element.innerHtml;
          final matched = regex.firstMatch(html);
          if (matched != null) {
            final String data = JsUnpack(html).unpack();
            // print(data);
            unpackedData = data;
            final dataMatch = RegExp(r'sources:\s*\[([\s\S]*?)\]').allMatches(data).firstOrNull?[1] ?? '';
            streamLink = dataMatch.replaceAll(RegExp(r'{|}|\"|file:'), '');
          }
        } finally {
          final subtitleData = RegExp(r'tracks:\[([\s\S]*?)\]').allMatches(unpackedData).firstOrNull;
          if (subtitleData != null) {
            subtitles = _extractEnglishSubtitleLink(subtitleData[1] ?? "");
          }
          final uri = Uri.tryParse(streamLink);
          if (uri == null || !uri.hasScheme) {
            final variables = streamLink.split("||");
            final extracted = _extractLinksObject(unpackedData);
            for (final variable in variables) {
              final parts = variable.split(".");
              if (parts.length == 2 && parts[0].trim() == 'links') {
                final key = parts[1].trim();
                final resolved = extracted[key];
                if (resolved != null)
                  streamLink = resolved;
                else
                  streamLink = "";
              }
            }
          }
        }
      }
    });
    if (streamLink.isEmpty) throw new Exception("Couldnt get any $serverName streams");
    return [
      VideoStream(
        server: serverName,
        link: streamLink,
        quality: "multi-quality",
        backup: false,
        subtitle: subtitles,
        subtitleFormat: subtitles != null ? subtitles!.endsWith(".vtt") ? "vtt" : "ass" : null,
        customHeaders: headersOverrides ?? {"Referer": streamUrl, "Origin": "https://${Uri.parse(streamUrl).host}"},
      )
    ];
  }

  String? _extractEnglishSubtitleLink(String input) {
    final regex = RegExp(r'\{[^}]*file\s*:\s*"([^"]+)"[^}]*label\s*:\s*"English"[^}]*kind\s*:\s*"captions"',
        caseSensitive: false, multiLine: true);
    final match = regex.firstMatch(input);
    return match != null ? match.group(1) : null;
  }

  Map<String, String> _extractLinksObject(String input) {
    final regex = RegExp(r'var\s+links\s*=\s*\{([\s\S]*?)\};');
    final match = regex.firstMatch(input);

    if (match == null) return {};

    final objectBody = match.group(1)!;
    final entries = RegExp(r'"?(\w+)"?\s*:\s*"((?:\\.|[^"\\])*)"')
        .allMatches(objectBody)
        .map((m) => MapEntry(m.group(1)!, m.group(2)!));

    return Map.fromEntries(entries);
  }
}
