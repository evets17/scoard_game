/// Text shown on a player's row for their score, such as "Bust".
class ScoreRowLabel {
  const ScoreRowLabel({required this.text, this.color});

  final String text;

  /// Colour as `#RRGGBB`, or null for the normal score colour.
  final String? color;

  @override
  bool operator ==(Object other) =>
      other is ScoreRowLabel && other.text == text && other.color == color;

  @override
  int get hashCode => Object.hash(text, color);
}
