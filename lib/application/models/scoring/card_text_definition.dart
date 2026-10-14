import 'package:scoard_game/application/models/scoring/card_text.dart';

/// A template's text for the player card: a score label, score sub label, or
/// player badge. It shows when [when] is true.
class CardTextDefinition {
  const CardTextDefinition({
    required this.when,
    required this.text,
    this.color,
    this.size = CardTextSize.large,
  });

  /// Formula; the text shows when it is not 0.
  final String when;

  /// The text, where `{name}` shows that value, for example
  /// `from {round-score}`.
  final String text;

  /// `#RRGGBB`, or null for the usual colour.
  final String? color;

  /// Only used for score labels.
  final CardTextSize size;
}
