import 'package:animestream/core/commons/types.dart';
import 'package:http/http.dart';

class Subtitleparsers {
  Future<List<Subtitle>> parseAss(String assSource) async {
    if(assSource.startsWith("https://")) {
      //its a link
      final res = await get(Uri.parse(assSource));
      final sub = ASSRIPPER().parseASS(res.body);
      return sub;
    };
    return ASSRIPPER().parseASS(assSource);
  }

  static Duration parseDuration(String timeString) {
    final parts = timeString.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    final secondsParts = parts[2].split('.');
    final seconds = int.parse(secondsParts[0]);
    final milliseconds = int.parse(secondsParts[1]);

    return Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      milliseconds: milliseconds,
    );
  }
}

class ASSRIPPER {
  List<Subtitle> parseASS(String rawAss) {
    final subtitles = <Subtitle >[];
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
    final dialogue = parts.last.replaceAll(r"\N", "\n").trim();

    return Subtitle(dialogue: dialogue, end: end, start: start);
  }
}