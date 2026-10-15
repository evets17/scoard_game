import 'package:scoard_game/application/models/results/round_score_player_result.dart';
import 'package:scoard_game/application/models/results/round_score_result.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/application/models/scoring/winner_rule.dart';
import 'package:scoard_game/application/models/sessions/round_score_round_values.dart';
import 'package:scoard_game/core/scoring/score_engine.dart';

RoundScoreResult calculateRoundScoreResult({
  required String sessionId,
  required ScoringPreset preset,
  required DateTime completedAt,
  required WinnerRule winnerRule,
  Map<String, int> options = const {},

  /// The name the game was played under; defaults to the template's name.
  String? gameName,
  required List<RoundScoreRoundValues> rounds,
}) {
  final engine = ScoreEngine.of(preset);
  final cumulativeScores = <String, int>{};
  final displayNames = <String, String>{};

  for (final round in rounds) {
    final roundScores = engine.scores(
      round.participantValues,
      roundNumber: round.roundNumber,
      options: options,
    );
    for (final participant in round.participantValues) {
      displayNames[participant.playerId] = participant.displayName;
      final roundScore = roundScores[participant.playerId] ?? 0;
      cumulativeScores.update(
        participant.playerId,
        (score) => score + roundScore,
        ifAbsent: () => roundScore,
      );
    }
  }

  final sortedEntries = cumulativeScores.entries.toList(growable: false)
    ..sort((left, right) {
      final scoreComparison = switch (winnerRule) {
        WinnerRule.highestScoreWins => right.value.compareTo(left.value),
        WinnerRule.lowestScoreWins => left.value.compareTo(right.value),
      };
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
    templateDisplayName: gameName ?? preset.displayName,
    completedAt: completedAt,
    winnerRule: winnerRule,
    roundCount: rounds.length,
    playerResults: playerResults,
  );
}