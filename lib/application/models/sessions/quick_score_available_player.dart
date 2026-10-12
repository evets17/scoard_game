class QuickScoreAvailablePlayer {
  const QuickScoreAvailablePlayer({
    required this.id,
    required this.displayName,
    this.groupIds = const {},
  });

  final String id;
  final String displayName;

  /// The player's groups, for filtering during setup. Not saved with games.
  final Set<String> groupIds;

  QuickScoreAvailablePlayer withCurrentPlayerName(
    Map<String, String> playerNames,
  ) {
    return QuickScoreAvailablePlayer(
      id: id,
      displayName: playerNames[id] ?? displayName,
      groupIds: groupIds,
    );
  }
}
