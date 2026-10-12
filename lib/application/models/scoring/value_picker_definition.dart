/// A template-defined way to enter a score by tapping the values in front of
/// a player, such as Skyjo cards. The score is the sum of what was tapped.
class ValuePickerDefinition {
  const ValuePickerDefinition({
    required this.id,
    required this.label,
    required this.options,
  });

  final String id;

  /// Names the mode, for example "Cards".
  final String label;
  final List<ValuePickerOption> options;
}

class ValuePickerOption {
  const ValuePickerOption({
    required this.value,
    this.label,
    this.color,
  });

  final int value;

  /// Shown under the number, for example "Hole".
  final String? label;

  /// Tile colour as `#RRGGBB`.
  final String? color;
}
