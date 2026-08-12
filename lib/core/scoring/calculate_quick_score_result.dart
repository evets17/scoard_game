import 'package:scoard_game/application/models/results/quick_score_player_result.dart';
import 'package:scoard_game/application/models/results/quick_score_result.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/application/models/scoring/winner_rule.dart';
import 'package:scoard_game/application/models/sessions/quick_score_participant_values.dart';

QuickScoreResult calculateQuickScoreResult({
  required String sessionId,
  required ScoringPreset preset,
  required DateTime completedAt,
  required List<QuickScoreParticipantValues> participantValues,
}) {
  final scoreFieldId = preset.scoreFields.firstWhere(
    (field) => field.contributesToFinalResult,
  ).id;

  final sortedParticipants = participantValues.toList(growable: false)
    ..sort((left, right) {
      final scoreComparison = _scoreFor(right, scoreFieldId)
          .compareTo(_scoreFor(left, scoreFieldId));

      if (scoreComparison != 0) {
        return scoreComparison;
      }

      return left.displayName.compareTo(right.displayName);
    });

  final playerResults = <QuickScorePlayerResult>[];
  var placement = 1;

  for (var index = 0; index < sortedParticipants.length; index++) {
    final participant = sortedParticipants[index];
    final score = _scoreFor(participant, scoreFieldId);

    if (index > 0) {
      final previousParticipant = sortedParticipants[index - 1];
      final previousScore = _scoreFor(previousParticipant, scoreFieldId);

      if (score != previousScore) {
        placement = index + 1;
      }
    }

    final sameScoreCount = sortedParticipants
        .where((otherParticipant) => _scoreFor(otherParticipant, scoreFieldId) == score)
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
    templateDisplayName: preset.displayName,
    completedAt: completedAt,
    winnerRule: WinnerRule.highestScoreWins,
    playerResults: playerResults,
  );
}

int _scoreFor(QuickScoreParticipantValues participant, String scoreFieldId) {
  return participant.enteredValues[scoreFieldId] ?? 0;
}