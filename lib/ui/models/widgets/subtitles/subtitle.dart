class Subtitle {
  final Duration start;
  final Duration end;
  final String dialogue;

  Subtitle({
    required this.dialogue,
    required this.end,
    required this.start,
  });

  @override
  String toString() => 'Subtitle(start: $start, end: $end, dialogue: $dialogue)';
}