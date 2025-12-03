import 'package:animestream/core/commons/subtitleParsers/subtitleParsers.dart';
import 'package:animestream/core/commons/subtitleParsers/util.dart';
import 'package:animestream/ui/models/widgets/subtitles/subtitle.dart';

class ASSRIPPER {
  List<Subtitle> parseASS(String rawAss) {
    final subtitles = <Subtitle>[];
    final eventLines = rawAss.split('\n').where((line) => line.startsWith('Dialogue:'));
    for (var eventLine in eventLines) {
      final parsed = _parseASSEventLine(eventLine);
      subtitles.add(parsed);
    }
    return subtitles;
  }

  String _removeASSFormatting(String text) {
    return text.replaceAll(RegExp(r'\{.*?\}'), '');
  }

  Subtitle _parseASSEventLine(String line) {
    final pattern = RegExp(r'^\{\\an(\d+)\}|^</?(\w+)>');
    final match = pattern.firstMatch(line);
    SubtitleAlignment alignment = SubtitleAlignment.bottomCenter;
    if (match != null) {
      if (match.group(1) != null) {
        final alignmentNumber = int.parse(match.group(1)!);
        alignment = SubtitleParserUtil.getAlignmentFromNumber(alignmentNumber);
      }
    }

    line = _removeASSFormatting(line);
    final parts = line.split(',');
    final start = Subtitleparsers.parseDuration(parts[1]);
    final end = Subtitleparsers.parseDuration(parts[2]);
    final dialogue = line.split(",,").last.replaceAll(r"\N", "\n").trim();

    return Subtitle(dialogue: dialogue, end: end, start: start, alignment: alignment);
  }
}
