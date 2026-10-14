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
  });

  final String id;

  /// Names the mode, for example "Cards".
  final String label;

  /// Every tile, in display order. Grouped tiles sit together.
  final List<ValuePickerOption> options;

  /// Formula for the score from the tapped tiles, or null to add them up.
  final String? total;
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

