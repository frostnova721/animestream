import 'package:html/parser.dart' as html;
import 'package:js_unpack/js_unpack.dart';
import '../../commons/types.dart';
import '../../commons/utils.dart';

class StreamWish {
// final streamUrl = "https://awish.pro/e/u0k9ocgf4ao0";
  // final streamUrl = "https://alions.pro/v/3jsdldq3ecz4";
  Future<List<Stream>> extract(String streamUrl) async {
    if (streamUrl.startsWith('https://awish.pro/')) {
      final res = await fetch(streamUrl);
      final doc = html.parse(res);
      String streamLink = '';
      doc.querySelectorAll('script').forEach((element) {
        if (streamLink.length == 0) {
          final regex = RegExp(r'file:\s*"(.*?)"');
          final link = regex.allMatches(element.innerHtml);
          if (link.isNotEmpty) {
            streamLink = link.firstOrNull?[1].toString() ?? '';
          }
        }
      });
      if (streamLink.isEmpty) throw new Exception("Couldnt get any awish streams");
      return [
        Stream(
            server: "streamwish",
            link: streamLink,
            quality: "multi-quality",
            backup: false,
            isM3u8: streamLink.endsWith('.m3u8'))
      ];
    }

    if (streamUrl.startsWith('https://alions.pro/')) {
      final res = await fetch(streamUrl);
      final doc = html.parse(res);
      String streamLink = '';
      doc.querySelectorAll('script').forEach((element) async {
        final html = element.innerHtml;
        final regex = RegExp(r'eval\(function\(p,a,c,k,e,d\)');
        final matched = regex.firstMatch(html);
        if (matched != null) {
          final String data = JsUnpack(html).unpack();

          final dataMatch = RegExp(r'\{sources:\s*\[([\s\S]*?)\]')
                  .allMatches(data)
                  .firstOrNull?[1] ??
              '';
          streamLink = dataMatch.replaceAll(RegExp(r'{|}|\"|file:'), '');
        }
      });
      if(streamLink.isEmpty) throw new Exception("Couldnt get any alions streams");
      return [
        Stream(
          quality: "multi-quality",
          link: streamLink,
          isM3u8: streamLink.endsWith('.m3u8'),
          server: "alions",
          backup: false,
        )
      ];
    }

    throw new Exception("NO_MATCHING_LINKS_FOUND");
  }

  // final matches = pattern.allMatches(content);

  // final streamInfos = matches.map((match) {
  //   final resolution = match.group(1);
  //   final link = match.group(2);
  //   return {
  //     'resolution': resolution,
  //     'link': link,
  //   };
  // }).toList();

  //   final List<Map<String, String>> streamList = [];
  //   final mainSplit = streamUrl.split('/');
  //   mainSplit.removeLast();
  //   final j = mainSplit.join('/');
  //   for (final info in streamInfos) {
  //     streamList.add({
  //       'resolution': info['resolution'] ?? '',
  //       'link': "$j/${info['link']}"
  //     });
  //   }
  //   return streamList;
  // }
//   }
}
