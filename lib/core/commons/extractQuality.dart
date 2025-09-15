import 'package:http/http.dart';

String _makeBaseLink(String uri) {
  final split = uri.split('/');
  split.removeLast();
  return split.join('/');
}

Future<List<Map<String, String>>> getQualityStreams(String streamUrl,
    {Map<String, String>? customHeader = null}) async {
  try {
  final content = (await get(Uri.parse(streamUrl), headers: customHeader)).body;

  List<String> links = [];
  List<String> resolutions = [];

  List<String> lines = content.split("\n");
  // lines = lines.where((it) => !it.startsWith("EXT-X-MEDIA")).toList().first.split("\n");

  final regex = RegExp(r'RESOLUTION=(\d+x\d+)');
  for (final line in lines) {
    if (line.startsWith("#")) {
      // we dont need these info yet
      // if (line.startsWith('#EXTM3U') || line.startsWith('#EXT-X-I-FRAME') || line.startsWith("#EXT-X-MEDIA") || line.startsWith("#EXT-X-VERSION"))
      if (!line.startsWith("#EXT-X-STREAM-INF")) continue;
      final match = regex.allMatches(line).first;
      resolutions.add(match.group(0)?.replaceAll("RESOLUTION=", '') ?? 'null');
    } else {
      final linkPart = line.trim();
      if (linkPart.length > 1)
        links.add(linkPart.startsWith('http') ? linkPart : "${_makeBaseLink(streamUrl)}/$linkPart");
    }
  }

  List<Map<String, String>> grouped = [];

  for (int i = 0; i < links.length; i++) {
    final Map<String, String> obj = {
      'link': links[i],
      'resolution': resolutions[i],
      'quality': resolutions[i].split('x')[1] + "p",
    };
    grouped.add(obj);
  }

  return grouped;
  } catch (err) {
    print(err);
    return [
      {'link': streamUrl, 'resolution': "", 'quality': 'default'}
    ];
  }
}
