import 'package:animestream/ui/models/widgets/subtitles/subtitle.dart';

class SubtitleParserUtil {
   static SubtitleAlignment getAlignmentFromNumber(int number) {
    return switch (number) {
      1 => SubtitleAlignment.bottomLeft,
      2 => SubtitleAlignment.bottomCenter,
      3 => SubtitleAlignment.bottomRight,
      4 => SubtitleAlignment.centerLeft,
      5 => SubtitleAlignment.center,
      6 => SubtitleAlignment.centerRight,
      7 => SubtitleAlignment.topLeft,
      8 => SubtitleAlignment.topCenter,
      9 => SubtitleAlignment.topRight,
      _ => throw Exception("Unknown position for sub")
    };
  }
}