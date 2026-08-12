String createPlayerId(String displayName, {DateTime? timestamp}) {
  final normalizedName = displayName
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  final resolvedTimestamp = timestamp ?? DateTime.now();

  return 'player-$normalizedName-${resolvedTimestamp.microsecondsSinceEpoch}';
}