import 'package:scoard_game/application/models/results/quick_score_result.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/application/models/sessions/quick_score_participant_values.dart';
import 'package:scoard_game/application/models/sessions/quick_score_session_id_rules.dart';
import 'package:scoard_game/application/repositories/session_repository.dart';
import 'package:scoard_game/core/scoring/calculate_quick_score_result.dart';

class SaveQuickScoreSession {
  const SaveQuickScoreSession({required this.sessionRepository});

  final SessionRepository sessionRepository;

  Future<QuickScoreResult> call({
    required ScoringPreset preset,
    required List<QuickScoreParticipantValues> participantValues,
    String? sessionId,
  }) async {
    if (participantValues.length < preset.minimumPlayers) {
      throw const QuickScoreValidationException(
        'Choose at least two players to score a game.',
      );
    }

    final scoreFieldId = preset.scoreFields.first.id;
    final hasMissingValues = participantValues.any(
      (participant) => !participant.enteredValues.containsKey(scoreFieldId),
    );

    if (hasMissingValues) {
      throw const QuickScoreValidationException(
        'Enter a score for every player.',
      );
    }

    final completedAt = DateTime.now();
    final result = calculateQuickScoreResult(
      sessionId: sessionId ?? createQuickScoreSessionId(timestamp: completedAt),
      preset: preset,
      completedAt: completedAt,
      participantValues: participantValues,
    );

    await sessionRepository.saveQuickScoreResult(
      result: result,
      participantValues: participantValues,
    );

    return result;
  }
}

class QuickScoreValidationException implements Exception {
  const QuickScoreValidationException(this.message);

  final String message;
}