import 'dart:convert';
import 'dart:io';

import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/commons/subtitleParsers/assParser.dart';
import 'package:animestream/core/commons/subtitleParsers/srtParser.dart';
import 'package:animestream/core/commons/subtitleParsers/vttParser.dart';
import 'package:animestream/ui/models/widgets/subtitles/subtitle.dart';
import 'package:animestream/core/network/network.dart';

class Subtitleparsers {
  Future<List<SubtitleCue>> parseSubs(String source, SubtitleFormat format) async {
    switch (format) {
      case SubtitleFormat.ASS:
        return ASSRIPPER().parseASS(source);
      case SubtitleFormat.VTT:
        return VttRipper().parseVtt(source);
      case SubtitleFormat.SRT:
        return SrtRipper().parseSrt(source);
    }
  }

  Future<List<SubtitleCue>> parseSubsFromUrl(String url, SubtitleFormat format, {Map<String, String> headers = const {}}) async {
    final res = await fetch(url, headers: headers);
    return parseSubs(utf8.decode(res.bodyBytes), format);
  }

  Future<List<SubtitleCue>> parseSubsFromFile(String filePath, SubtitleFormat format) async {
    final res = await File(filePath).readAsBytes();
    return parseSubs(utf8.decode(res), format);
  }

  Future<Response> fetch(String url, {Map<String, String> headers = const {}}) async {
    final res = await get(Uri.parse(url), headers: headers);
    if (res.statusCode >= 200 && res.statusCode <= 299) {
      return res;
    }
    throw Exception("Couldnt fetch the subtitles file. Server responded with status ${res.statusCode}");
  }

  static Duration parseDuration(String timeString) {
    final parts = timeString.trim().split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    final secondsParts = parts[2].split(RegExp(r'[.,]'));
    final seconds = int.parse(secondsParts[0]);
    final fractionStr = secondsParts.length > 1 ? secondsParts[1] : '0';
    // Normalize fraction to milliseconds: pad/truncate to 3 digits (ASS uses centiseconds)
    final msStr = (fractionStr.length >= 3) ? fractionStr.substring(0, 3) : fractionStr.padRight(3, '0');
    final milliseconds = int.parse(msStr);

    return Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      milliseconds: milliseconds,
    );
  }
}
