import 'package:scoard_game/application/models/results/round_score_result.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/application/models/sessions/quick_score_session_id_rules.dart';
import 'package:scoard_game/application/models/sessions/round_score_round_values.dart';
import 'package:scoard_game/application/repositories/session_repository.dart';
import 'package:scoard_game/core/scoring/calculate_round_score_result.dart';

class SaveRoundScoreSession {
  const SaveRoundScoreSession({required this.sessionRepository});

  final SessionRepository sessionRepository;

  Future<RoundScoreResult> call({
    required ScoringPreset preset,
    required List<RoundScoreRoundValues> rounds,
    String? sessionId,
  }) async {
    if (rounds.isEmpty) {
      throw const RoundScoreValidationException('Complete at least one round.');
    }

    final minimumPlayers = preset.minimumPlayers;
    final scoreFieldId = preset.scoreFields.first.id;

    for (final round in rounds) {
      if (round.participantValues.length < minimumPlayers) {
        throw const RoundScoreValidationException(
          'Choose at least two players to score a game.',
        );
      }

      final hasMissingValues = round.participantValues.any(
        (participant) => !participant.enteredValues.containsKey(scoreFieldId),
      );
      if (hasMissingValues) {
        throw const RoundScoreValidationException(
          'Enter a score for every player in the round.',
        );
      }
    }

    final completedAt = DateTime.now();
    final result = calculateRoundScoreResult(
      sessionId: sessionId ?? createQuickScoreSessionId(timestamp: completedAt),
      preset: preset,
      completedAt: completedAt,
      rounds: rounds,
    );

    await sessionRepository.saveRoundScoreResult(
      result: result,
      rounds: rounds,
    );

    return result;
  }
}

class RoundScoreValidationException implements Exception {
  const RoundScoreValidationException(this.message);

  final String message;
}