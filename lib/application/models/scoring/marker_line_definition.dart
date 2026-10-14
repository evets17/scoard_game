/// A per-player, per-round flag that players set by hand, such as Skyjo's
/// "Went out first". Formulas read it as 1 when set and 0 when not.
///
/// It is stored like an entered value, so it is saved with the game and its
/// results, and it does not change when the player's score is edited.
class MarkerLineDefinition {
  const MarkerLineDefinition({
    required this.id,
    required this.label,
    required this.badge,
    this.color,
    this.onePerRound = false,
  });

  final String id;

  /// What the toggle in the score sheet says, for example "Went out first".
  final String label;

  /// Shown beside the player's name while set, for example "Out".
  final String badge;

  /// Badge colour as `#RRGGBB`.
  final String? color;

  /// Setting it for one player clears it for everyone else in the round.
  final bool onePerRound;
}
