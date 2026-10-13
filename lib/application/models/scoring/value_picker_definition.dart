import 'package:scoard_game/application/models/scoring/score_row_label.dart';

/// A template-defined way to enter a score by tapping the values in front of
/// a player, such as Skyjo cards.
///
/// Without [total] the score is the sum of the tapped tiles. With it, tiles
/// belong to groups and [total] is a formula over the group totals, for
/// example to double only number cards.
class ValuePickerDefinition {
  const ValuePickerDefinition({
    required this.id,
    required this.label,
    required this.options,
    this.total,
    this.rowLabels = const [],
  });

  final String id;

  /// Names the mode, for example "Cards".
  final String label;

  /// Every tile, in display order. Grouped tiles sit together.
  final List<ValuePickerOption> options;

  /// Formula for the score from the tapped tiles, or null to add them up.
  final String? total;

  /// Labels shown on the row instead of the score when the picked tiles
  /// match, checked in order. The first match is used.
  final List<ValuePickerRowLabel> rowLabels;
}

class ValuePickerOption {
  const ValuePickerOption({
    required this.value,
    this.label,
    this.color,
    this.text,
    this.groupId,
  });

  final int value;

  /// Shown under the main text, for example "Hole".
  final String? label;

  /// Tile colour as `#RRGGBB`.
  final String? color;

  /// Shown on the tile instead of the value, for example "+4" or "×2".
  final String? text;

  /// The tile group this belongs to, when the picker has groups.
  final String? groupId;

  String get displayText => text ?? '$value';
}

/// A label to show on the player's row when [when] is true for the picked
/// tiles, for example "Bust" when the bust tile was picked.
class ValuePickerRowLabel {
  const ValuePickerRowLabel({
    required this.when,
    required this.text,
    this.isBadge = false,
    this.size = RowLabelSize.large,
    this.color,
  });

  /// Formula over the picker's groups; non-zero means the label applies.
  final String when;
  final String text;

  /// True to show as a small badge beside the player's name, keeping the
  /// score visible. False to show instead of the score.
  final bool isBadge;

  /// Text size when shown instead of the score.
  final RowLabelSize size;

  /// Text colour, or the badge colour, as `#RRGGBB`.
  final String? color;
}
