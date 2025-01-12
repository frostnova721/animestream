import 'package:animestream/ui/models/subtitles.dart';
import 'package:http/http.dart';

class Subtitleparsers {
  Future<List<Subtitle>> parseAss(String assSource) async {
    if (assSource.startsWith("https://")) {
      //its a link
      final res = await get(Uri.parse(assSource));
      final sub = ASSRIPPER().parseASS(res.body);
      return sub;
    }
    ;
    return ASSRIPPER().parseASS(assSource);
  }

  Future<List<Subtitle>> parseVtt(String source) async {
    if (source.startsWith('https://')) {
      final res = await get(Uri.parse(source));
      final subs = VttRipper().parseVtt(res.body);
      return subs;
    }
    return VttRipper().parseVtt(source);
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
    final dialogue = parts.last.replaceAll(r"\N", "\n").trim();

    return Subtitle(dialogue: dialogue, end: end, start: start);
  }
}

//GPT CODE!!!
class VttRipper {
  List<Subtitle> parseVtt(String rawSource) {
    final lines = rawSource.split('\n');
    final subtitles = <Subtitle>[];

    String? currentDialogue;
    Duration? start;
    Duration? end;

    for (final line in lines) {
      // Skip metadata lines
      if (line.startsWith('WEBVTT') || line.trim().isEmpty || line.startsWith('NOTE')) {
        // If we encounter an empty line, it's the end of a block
        if (currentDialogue != null && start != null && end != null) {
          subtitles.add(Subtitle(start: start, end: end, dialogue: _removeHtml(currentDialogue)));
          currentDialogue = null;
          start = null;
          end = null;
        }
        continue;
      }

      // Parse timestamp line
      if (line.contains('-->')) {
        final times = line.split('-->');
        if (times.length != 2) {
          throw FormatException('Invalid timestamp line: $line');
        }
        start = _parseTime(times[0].trim());
        end = _parseTime(times[1].trim());
      } else if (start != null && end != null) {
        // Collect dialogue lines
        currentDialogue = (currentDialogue == null) ? line : '$currentDialogue\n$line';
      }
    }

    // Add the last subtitle if the file ends without an empty line
    if (start != null && end != null && currentDialogue != null) {
      subtitles.add(Subtitle(start: start, end: end, dialogue: _removeHtml(currentDialogue)));
    }

    return subtitles;
  }

  String _removeHtml(String dialogue) {
    final tagRegExp = RegExp(r'<[^>]*>');
    return dialogue.replaceAll(tagRegExp, "");
  }

  Duration _parseTime(String time) {
    final parts = time.split(':');
    if (parts.length == 3) {
      // Format is HH:MM:SS.MS
      return Duration(
        hours: int.parse(parts[0]),
        minutes: int.parse(parts[1]),
        milliseconds: (double.parse(parts[2]) * 1000).round(),
      );
    } else if (parts.length == 2) {
      // Format is MM:SS.MS
      return Duration(
        minutes: int.parse(parts[0]),
        milliseconds: (double.parse(parts[1]) * 1000).round(),
      );
    }
    throw FormatException('Invalid time format: $time');
  }
}
