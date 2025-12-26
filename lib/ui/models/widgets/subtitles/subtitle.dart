class Subtitle {
  final Duration start;
  final Duration end;
  final String dialogue;
  final SubtitleAlignment alignment;

  Subtitle(
      {required this.dialogue,
      required this.end,
      required this.start,
      this.alignment = SubtitleAlignment.bottomCenter // maybe later!
      });

  @override
  String toString() => 'Subtitle(start: $start, end: $end, dialogue: $dialogue, alignment: $alignment)';
}

// numbers for numpad type alignment in srt/ass
enum SubtitleAlignment {
  bottomLeft, // 1
  bottomCenter, // 2
  bottomRight, // 3
  centerLeft, // 4
  center, // 5
  centerRight, // 6
  topLeft, // 7
  topCenter, // 8
  topRight, // 9
}
