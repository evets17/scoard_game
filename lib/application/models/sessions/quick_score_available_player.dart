class QuickScoreAvailablePlayer {
  const QuickScoreAvailablePlayer({
    required this.id,
    required this.displayName,
  });

  final String id;
  final String displayName;

  QuickScoreAvailablePlayer withCurrentPlayerName(
    Map<String, String> playerNames,
  ) {
    return QuickScoreAvailablePlayer(
      id: id,
      displayName: playerNames[id] ?? displayName,
    );
  }
}
