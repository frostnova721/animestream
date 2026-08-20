import 'dart:convert';
import 'dart:io';

import 'package:animestream/core/commons/subtitleParsers/srtParser.dart';
import 'package:animestream/core/commons/subtitleParsers/vttParser.dart';
import 'package:animestream/ui/models/widgets/subtitles/subtitle.dart';

enum SubtitleAlignment { bottomCenter }


class ParsedSubtitles {
  final List<SubtitleCue> cues;
  final String codecId;

  ParsedSubtitles(this.cues, this.codecId);
}

class SubtitleParser {
  static Future<ParsedSubtitles> parseFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return ParsedSubtitles([], 'S_TEXT/UTF8');
    }

    final content = await file.readAsString(encoding: utf8);
    final text = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // For standard VTT identification 
    if (text.trimLeft().startsWith('WEBVTT')) {
      return ParsedSubtitles(VttRipper().parseVtt(text), 'D_WEBVTT/SUBTITLES');
    } else {
      return ParsedSubtitles(SrtRipper().parseSrt(text), 'S_TEXT/UTF8');
    }
  }
}