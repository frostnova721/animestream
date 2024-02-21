import '../../commons/utils.dart';

class StreamWish {
  Future<List<Map<String, String>>> getStreams(String streamUrl) async {
  final content = await fetch(streamUrl);

  final pattern = RegExp(
    r'#EXT-X-STREAM-INF:.*?RESOLUTION=(\d+x\d+).*?\n(.*?)\n',
    multiLine: true,
  );

  final matches = pattern.allMatches(content);

  final streamInfos = matches.map((match) {
    final resolution = match.group(1);
    final link = match.group(2);
    return {
      'resolution': resolution,
      'link': link,
    };
  }).toList();

  final List<Map<String, String>> streamList = [];
  final mainSplit = streamUrl.split('/');
  mainSplit.removeLast();
  final j = mainSplit.join('/');
  for (final info in streamInfos) {
    streamList
        .add({'resolution': info['resolution'] ?? '', 'link': "$j/${info['link']}"});
  }
  return streamList;
}
}