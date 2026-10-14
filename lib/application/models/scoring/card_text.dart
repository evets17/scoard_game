/// How large a score label is drawn in place of the score. The score number
/// itself always keeps its normal size.
enum CardTextSize { small, medium, large }

/// Text a template shows on the player card, filled in for one player: a
/// score label (instead of the score, such as "Bust"), a score sub label
/// (under the score, such as "from 10"), or a player badge (after the name,
/// such as "1st"). Marker badges use it too.
class CardText {
  const CardText({
    required this.text,
    this.color,
    this.size = CardTextSize.large,
  });

  final String text;

  /// Colour as `#RRGGBB`, or null for the usual colour.
  final String? color;

  /// Only used for score labels.
  final CardTextSize size;

  @override
  bool operator ==(Object other) =>
      other is CardText &&
      other.text == text &&
      other.color == color &&
      other.size == size;

  @override
  int get hashCode => Object.hash(text, color, size);
}

/// Everything a template shows on one player's card besides the name and
/// score.
class PlayerCardTexts {
  const PlayerCardTexts({
    this.scoreLabel,
    this.scoreSubLabel,
    this.playerBadges = const [],
  });

  static const none = PlayerCardTexts();

  /// Shown instead of the score: the first score label that applies.
  final CardText? scoreLabel;

  /// Shown under the score: the first score sub label that applies.
  final CardText? scoreSubLabel;

  /// Shown after the name: every player badge that applies.
  final List<CardText> playerBadges;
}
