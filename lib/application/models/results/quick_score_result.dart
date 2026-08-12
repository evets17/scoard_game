import 'package:scoard_game/application/models/results/quick_score_player_result.dart';
import 'package:scoard_game/application/models/scoring/winner_rule.dart';

class QuickScoreResult {
  const QuickScoreResult({
    required this.sessionId,
    required this.templateId,
    required this.templateDisplayName,
    required this.completedAt,
    required this.winnerRule,
    required this.playerResults,
  });

  final String sessionId;
  final String templateId;
  final String templateDisplayName;
  final DateTime completedAt;
  final WinnerRule winnerRule;
  final List<QuickScorePlayerResult> playerResults;

  List<QuickScorePlayerResult> get winners {
    if (playerResults.isEmpty) {
      return const [];
    }

    final topPlacement = playerResults.first.placement;
    return playerResults
        .where((playerResult) => playerResult.placement == topPlacement)
        .toList(growable: false);
  }
}