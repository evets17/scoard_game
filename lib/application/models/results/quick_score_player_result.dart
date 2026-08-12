class QuickScorePlayerResult {
  const QuickScorePlayerResult({
    required this.playerId,
    required this.displayName,
    required this.finalScore,
    required this.placement,
    required this.isTied,
  });

  final String playerId;
  final String displayName;
  final int finalScore;
  final int placement;
  final bool isTied;
}