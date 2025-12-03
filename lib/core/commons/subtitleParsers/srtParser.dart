import 'package:animestream/core/commons/subtitleParsers/util.dart';
import 'package:animestream/ui/models/widgets/subtitles/subtitle.dart';
// import 'package:flutter/widgets.dart';

class SrtRipper {
  List<Subtitle> parseSrt(String rawSource) {
    final List<Subtitle> subs = [];
    final sections = rawSource.split(RegExp(r"\r\n\r\n|\n\n|\r\r"));
    for (final section in sections) {
      final lines = section.split(RegExp(r"\n|\r\n|\r"));
      if (lines.isEmpty) continue;
      if (lines.length < 3) continue; // there should atleast be 2 lines bru
      final timestamps = lines[1];
      final tsSplit = timestamps.split("-->");
      final start = _parseTimestamp(tsSplit[0]);
      final end = _parseTimestamp(tsSplit[1]);
      String text = lines.sublist(2).join('\n').trim();
      final pattern = RegExp(r'^\{\\an(\d+)\}|^</?(\w+)>');
      final match = pattern.firstMatch(text);
      SubtitleAlignment alignment = SubtitleAlignment.bottomCenter;
      if (match != null) {
        if (match.group(1) != null) {
          final alignmentNumber = int.parse(match.group(1)!);
          alignment = SubtitleParserUtil.getAlignmentFromNumber(alignmentNumber);
        }
        //  else if (match.group(2) != null) {
          // final tagName = match.group(2)!;
        // }
        text = text.replaceAll(RegExp(r'</?\w+>|{\\an\d+}'), "");
      }
      subs.add(Subtitle(dialogue: text, end: end, start: start, alignment: alignment,));
    }
    return subs;
  }

  Duration _parseTimestamp(String timestamp) {
    final hr_m_s = timestamp.split(":");
    final s_ms = hr_m_s[2].split(",");
    return Duration(
        hours: int.parse(hr_m_s[0]),
        minutes: int.parse(hr_m_s[1]),
        seconds: int.parse(s_ms[0]),
        milliseconds: int.parse(s_ms[1]));
  }
}
