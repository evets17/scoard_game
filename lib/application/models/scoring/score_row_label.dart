/// How large a label shown instead of the score is drawn. The score number
/// itself always keeps its normal size.
enum RowLabelSize { small, medium, large }

/// Text shown on a player's row for their score, such as "Bust".
class ScoreRowLabel {
  const ScoreRowLabel({
    required this.text,
    this.color,
    this.size = RowLabelSize.large,
  });

  final String text;

  /// Colour as `#RRGGBB`, or null for the normal score colour.
  final String? color;

  /// Only used when the label is shown instead of the score.
  final RowLabelSize size;

  @override
  bool operator ==(Object other) =>
      other is ScoreRowLabel &&
      other.text == text &&
      other.color == color &&
      other.size == size;

  @override
  int get hashCode => Object.hash(text, color, size);
}
