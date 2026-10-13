/// A colour given to a player for one game, usually to match their pawn.
/// Belongs to the player's place in the game, not to the player.
enum PlayerColor {
  red('Red'),
  orange('Orange'),
  yellow('Yellow'),
  green('Green'),
  blue('Blue'),
  purple('Purple'),
  pink('Pink'),
  brown('Brown'),
  black('Black'),
  white('White');

  const PlayerColor(this.label);

  final String label;

  static PlayerColor? fromStorage(Object? value) {
    for (final color in values) {
      if (color.name == value) {
        return color;
      }
    }
    return null;
  }

  /// Reads a saved `{playerId: colorName}` map, skipping unknown colours.
  static Map<String, PlayerColor> mapFromJson(Object? json) {
    final raw = (json as Map<String, Object?>?) ?? const {};
    return {
      for (final entry in raw.entries)
        if (fromStorage(entry.value) case final PlayerColor color)
          entry.key: color,
    };
  }

  static Map<String, String> mapToJson(Map<String, PlayerColor> colors) => {
        for (final entry in colors.entries) entry.key: entry.value.name,
      };
}
