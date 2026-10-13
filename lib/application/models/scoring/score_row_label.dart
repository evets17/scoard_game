/// Text shown on a player's row in place of their score, such as "Bust".
class ScoreRowLabel {
  const ScoreRowLabel({required this.text, this.color});

  final String text;

  /// Text colour as `#RRGGBB`, or null for the normal score colour.
  final String? color;

  Map<String, Object?> toJson() => {'text': text, 'color': color};

  factory ScoreRowLabel.fromJson(Map<String, Object?> json) {
    return ScoreRowLabel(
      text: json['text']! as String,
      color: json['color'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ScoreRowLabel && other.text == text && other.color == color;

  @override
  int get hashCode => Object.hash(text, color);
}
