import 'package:scoard_game/application/models/results/quick_score_player_result.dart';
import 'package:scoard_game/application/models/results/quick_score_result.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/application/models/scoring/winner_rule.dart';
import 'package:scoard_game/application/models/sessions/quick_score_participant_values.dart';
import 'package:scoard_game/core/scoring/score_engine.dart';

QuickScoreResult calculateQuickScoreResult({
  required String sessionId,
  required ScoringPreset preset,
  required DateTime completedAt,
  required WinnerRule winnerRule,
  Map<String, int> options = const {},

  /// The name the game was played under; defaults to the template's name.
  String? gameName,
  required List<QuickScoreParticipantValues> participantValues,
}) {
  final scores = ScoreEngine.of(preset).scores(
    participantValues,
    roundNumber: 1,
    options: options,
  );
  int scoreFor(QuickScoreParticipantValues participant) =>
      scores[participant.playerId] ?? 0;

  final sortedParticipants = participantValues.toList(growable: false)
    ..sort((left, right) {
      final scoreComparison = switch (winnerRule) {
        WinnerRule.highestScoreWins => scoreFor(right)
            .compareTo(scoreFor(left)),
        WinnerRule.lowestScoreWins => scoreFor(left)
            .compareTo(scoreFor(right)),
      };

      if (scoreComparison != 0) {
        return scoreComparison;
      }

      return left.displayName.compareTo(right.displayName);
    });

  final playerResults = <QuickScorePlayerResult>[];
  var placement = 1;

  for (var index = 0; index < sortedParticipants.length; index++) {
    final participant = sortedParticipants[index];
    final score = scoreFor(participant);

    if (index > 0) {
      final previousParticipant = sortedParticipants[index - 1];
      final previousScore = scoreFor(previousParticipant);

      if (score != previousScore) {
        placement = index + 1;
      }
    }

    final sameScoreCount = sortedParticipants
        .where((otherParticipant) => scoreFor(otherParticipant) == score)
        .length;

    playerResults.add(
      QuickScorePlayerResult(
        playerId: participant.playerId,
        displayName: participant.displayName,
        finalScore: score,
        placement: placement,
        isTied: sameScoreCount > 1,
      ),
    );
  }

  return QuickScoreResult(
    sessionId: sessionId,
    templateId: preset.id,
    templateDisplayName: gameName ?? preset.displayName,
    completedAt: completedAt,
    winnerRule: winnerRule,
    playerResults: playerResults,
  );
}
