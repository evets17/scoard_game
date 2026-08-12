class RoundScorePlayerResult {
  const RoundScorePlayerResult({
    required this.playerId,
    required this.displayName,
    required this.cumulativeScore,
    required this.placement,
    required this.isTied,
  });

  final String playerId;
  final String displayName;
  final int cumulativeScore;
  final int placement;
  final bool isTied;
}