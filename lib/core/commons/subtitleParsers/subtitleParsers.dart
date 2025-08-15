import 'dart:convert';

import 'package:animestream/core/commons/subtitleParsers/assParser.dart';
import 'package:animestream/core/commons/subtitleParsers/srtParser.dart';
import 'package:animestream/core/commons/subtitleParsers/vttParser.dart';
import 'package:animestream/ui/models/widgets/subtitles/subtitle.dart';
import 'package:http/http.dart';

class Subtitleparsers {
  Future<List<Subtitle>> parseAss(String assSource, { Map<String, String> headers = const {}}) async {
    if (assSource.startsWith("https://")) {
      //its a link
      final res = await get(Uri.parse(assSource), headers: headers);
      final sub = ASSRIPPER().parseASS(utf8.decode(res.bodyBytes));
      return sub;
    }
    ;
    return ASSRIPPER().parseASS(assSource);
  }

  Future<List<Subtitle>> parseVtt(String source, { Map<String, String> headers = const {}}) async {
    if (source.startsWith('https://')) {
      final res = await get(Uri.parse(source), headers: headers);
      final subs = VttRipper().parseVtt(utf8.decode(res.bodyBytes));
      return subs;
    }
    return VttRipper().parseVtt(source);
  }

  Future<List<Subtitle>> parseSrt(String source, { Map<String, String> headers = const {}}) async {
    if (source.startsWith('https://')) {
      final res = await get(Uri.parse(source), headers: headers);
      final subs = SrtRipper().parseSrt(utf8.decode(res.bodyBytes));
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

