import 'dart:convert';

import 'package:http/http.dart';

class AniSkip {
  final String _baseUrl = "https://api.aniskip.com/v2";

  Future<AniSkipResult?> getSkipTimes(int malId, int episodeNumber, {double episodeLength = 0}) async {
    final url = "$_baseUrl/skip-times/${malId}/${episodeNumber}?types=op&types=ed&episodeLength=$episodeLength";
    print(url);

    final res = await get(Uri.parse(url));

    if (res.statusCode != 200) {
      print("Failed to fetch skip times. Status code: ${res.statusCode}");
      return null;
    }

    final data = res.body;

    final json = jsonDecode(data);

    if (json['found'] != true) {
      print("No skip data found");
      return null;
    }

    return _serializeResult(List.castFrom(json['results']));
  }

  AniSkipResult _serializeResult(List<Map<String, dynamic>> results) {
    SkipInterval? op, ed;

    for (final item in results) {
      final type = item['skipType'] as String;
      final id = item['skipId'] as String;
      final length = item['episodeLength'] as double;

      final skipInterval = SkipInterval(
        // These values are always a double, but dart automatically converts some values
        // to int, and throws an error if we try to cast a double to it.
        // And... we dont want double, so we assert it to int via toInt()
        start: (item['interval']['startTime']!).toInt(), // lets ignore the +/- 1 sec offset
        end: (item['interval']['endTime']!).toInt(),
        id: id,
        epLength: length,
      );


      type == "op" ? op = skipInterval : ed = skipInterval;
    }
    return AniSkipResult(op: op, ed: ed);
  }
}

class AniSkipResult {
  final SkipInterval? op;
  final SkipInterval? ed;

  AniSkipResult({this.op = null, this.ed = null});

  @override
  String toString() {
    return "AniSkipResult(op: $op, ed: $ed)";
  }
}

class SkipInterval {
  final int start;
  final int end;
  final String id;
  final double epLength;

  SkipInterval({required this.start, required this.end, required this.epLength, required this.id});

  @override
  String toString() {
    return "SkipInterval(start: $start, end: $end, id: $id, epLength: $epLength)";
  }
}
