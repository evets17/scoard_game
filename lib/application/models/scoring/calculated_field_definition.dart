/// A field whose value comes from a formula rather than being entered.
class CalculatedFieldDefinition {
  const CalculatedFieldDefinition({
    required this.id,
    required this.label,
    required this.formula,
  });

  final String id;
  final String label;

  /// For example `max(0, {inning-points} - highestOther(inning-points))`.
  final String formula;
}
