import 'package:scoard_game/application/models/results/round_score_player_result.dart';
import 'package:scoard_game/application/models/results/round_score_result.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/application/models/scoring/winner_rule.dart';
import 'package:scoard_game/application/models/sessions/round_score_round_values.dart';

RoundScoreResult calculateRoundScoreResult({
  required String sessionId,
  required ScoringPreset preset,
  required DateTime completedAt,
  required List<RoundScoreRoundValues> rounds,
}) {
  final scoreFieldId = preset.scoreFields.firstWhere(
    (field) => field.contributesToFinalResult,
  ).id;
  final cumulativeScores = <String, int>{};
  final displayNames = <String, String>{};

  for (final round in rounds) {
    for (final participant in round.participantValues) {
      displayNames[participant.playerId] = participant.displayName;
      cumulativeScores.update(
        participant.playerId,
        (score) => score + (participant.enteredValues[scoreFieldId] ?? 0),
        ifAbsent: () => participant.enteredValues[scoreFieldId] ?? 0,
      );
    }
  }

  final sortedEntries = cumulativeScores.entries.toList(growable: false)
    ..sort((left, right) {
      final scoreComparison = right.value.compareTo(left.value);
      if (scoreComparison != 0) {
        return scoreComparison;
      }

      return (displayNames[left.key] ?? '').compareTo(displayNames[right.key] ?? '');
    });

  final playerResults = <RoundScorePlayerResult>[];
  var placement = 1;

  for (var index = 0; index < sortedEntries.length; index++) {
    final entry = sortedEntries[index];
    if (index > 0 && entry.value != sortedEntries[index - 1].value) {
      placement = index + 1;
    }

    final sameScoreCount = sortedEntries.where((other) => other.value == entry.value).length;
    playerResults.add(
      RoundScorePlayerResult(
        playerId: entry.key,
        displayName: displayNames[entry.key] ?? entry.key,
        cumulativeScore: entry.value,
        placement: placement,
        isTied: sameScoreCount > 1,
      ),
    );
  }

  return RoundScoreResult(
    sessionId: sessionId,
    templateId: preset.id,
    templateDisplayName: preset.displayName,
    completedAt: completedAt,
    winnerRule: WinnerRule.highestScoreWins,
    roundCount: rounds.length,
    playerResults: playerResults,
  );
}