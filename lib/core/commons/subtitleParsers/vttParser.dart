//GPT CODE!!!
import 'package:animestream/ui/models/widgets/subtitles/subtitle.dart';

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
