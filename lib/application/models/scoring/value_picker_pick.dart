/// The tiles tapped in a value picker for one entry, kept so the picker can
/// reopen with them, and so card text can read them.
///
/// Tiles are recorded by what they show ("8", "+4", "×2") rather than by
/// position, so a later change to the template cannot point at the wrong
/// tile.
class ValuePickerPick {
  const ValuePickerPick({required this.pickerId, required this.tiles});

  final String pickerId;

  /// Tile texts in the order they were tapped.
  final List<String> tiles;

  Map<String, Object?> toJson() => {'pickerId': pickerId, 'tiles': tiles};

  factory ValuePickerPick.fromJson(Map<String, Object?> json) {
    return ValuePickerPick(
      pickerId: json['pickerId']! as String,
      tiles: [for (final tile in json['tiles']! as List<Object?>) tile! as String],
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ValuePickerPick &&
      other.pickerId == pickerId &&
      other.tiles.length == tiles.length &&
      Iterable.generate(tiles.length).every((i) => other.tiles[i] == tiles[i]);

  @override
  int get hashCode => Object.hash(pickerId, Object.hashAll(tiles));
}
