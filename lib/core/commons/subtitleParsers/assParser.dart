import 'package:animestream/core/commons/subtitleParsers/subtitleParsers.dart';
import 'package:animestream/ui/models/widgets/subtitles/subtitle.dart';

class ASSRIPPER {
  List<Subtitle> parseASS(String rawAss) {
    final subtitles = <Subtitle>[];
    final eventLines = rawAss.split('\n').where((line) => line.startsWith('Dialogue:'));
    for (var eventLine in eventLines) {
      final parsed = _parseASSEventLine(_removeASSFormatting(eventLine));
      subtitles.add(parsed);
    }
    return subtitles;
  }

  String _removeASSFormatting(String text) {
    return text.replaceAll(RegExp(r'\{.*?\}'), '');
  }

  Subtitle _parseASSEventLine(String line) {
    final parts = line.split(',');
    final start = Subtitleparsers.parseDuration(parts[1]);
    final end = Subtitleparsers.parseDuration(parts[2]);
    final dialogue = line.split(",,").last.replaceAll(r"\N", "\n").trim();

    return Subtitle(dialogue: dialogue, end: end, start: start);
  }
}

