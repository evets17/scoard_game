import 'package:scoard_game/application/models/results/round_score_player_result.dart';
import 'package:scoard_game/application/models/scoring/winner_rule.dart';

class RoundScoreResult {
  const RoundScoreResult({
    required this.sessionId,
    required this.templateId,
    required this.templateDisplayName,
    required this.completedAt,
    required this.winnerRule,
    required this.roundCount,
    required this.playerResults,
  });

  final String sessionId;
  final String templateId;
  final String templateDisplayName;
  final DateTime completedAt;
  final WinnerRule winnerRule;
  final int roundCount;
  final List<RoundScorePlayerResult> playerResults;

  List<RoundScorePlayerResult> get winners {
    if (playerResults.isEmpty) {
      return const [];
    }

    final topPlacement = playerResults.first.placement;
    return playerResults
        .where((playerResult) => playerResult.placement == topPlacement)
        .toList(growable: false);
  }
}