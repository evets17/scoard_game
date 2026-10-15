/// A line whose value comes from a formula rather than being entered.
class CalculatedLineDefinition {
  const CalculatedLineDefinition({
    required this.id,
    required this.label,
    required this.formula,
    this.hidden = false,
  });

  final String id;
  final String label;

  /// For example `max(0, {inning-points} - highestOther(inning-points))`.
  final String formula;

  /// Worked out but not shown as a row of the score sheet, for a value
  /// that other lines or text read, such as a bonus shown as "+3".
  final bool hidden;
}
