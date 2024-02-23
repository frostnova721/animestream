import 'package:animestream/core/commons/utils.dart';

String _makeBaseLink(String uri) {
  final split = uri.split('/');
  split.removeLast();
  return split.join('/');
}

Future<List<Map<String, String>>> getQualityStreams(String streamUrl) async {
  final content = await fetch(streamUrl);

  List<String> links = [];
  List<String> resolutions = [];

  final lines = content.split('\n\n')[0].split('\n');
  final regex = RegExp(r'RESOLUTION=(\d+x\d+)');
  for (final line in lines) {
    if (line.startsWith("#")) {
      if (line.startsWith('#EXTM3U') || line.startsWith('#EXT-X-I-FRAME'))
        continue;
      final match = regex.allMatches(line).first;
      resolutions.add(match.group(0)?.replaceAll("RESOLUTION=", '') ?? 'null');
    } else {
      final linkPart = line.trim();
      if (linkPart.length > 1)
        links.add(linkPart.startsWith('http')
            ? linkPart
            : "${_makeBaseLink(streamUrl)}/$linkPart");
    }
  }

  List<Map<String, String>> grouped = [];

  for (int i = 0; i < links.length; i++) {
    final Map<String, String> obj = {
      'link': links[i],
      'resolution': resolutions[i],
      'quality': resolutions[i].split('x')[1],
    };
    grouped.add(obj);
  }

  return grouped;
}
