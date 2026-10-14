import 'package:scoard_game/application/models/scoring/preset_prompt_answer.dart';
import 'package:scoard_game/application/models/results/quick_score_result.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/application/models/sessions/quick_score_participant_values.dart';
import 'package:scoard_game/application/models/sessions/quick_score_session_id_rules.dart';
import 'package:scoard_game/application/repositories/session_repository.dart';
import 'package:scoard_game/core/scoring/calculate_quick_score_result.dart';
import 'package:scoard_game/core/scoring/resolve_preset_options.dart';

class SaveQuickScoreSession {
  const SaveQuickScoreSession({required this.sessionRepository});

  final SessionRepository sessionRepository;

  Future<QuickScoreResult> call({
    required ScoringPreset preset,
    required List<QuickScoreParticipantValues> participantValues,
    List<PresetPromptAnswer> promptAnswers = const [],
    String? sessionId,
  }) async {
    if (participantValues.length < preset.minimumPlayers) {
      throw const QuickScoreValidationException(
        'Choose at least two players to score a game.',
      );
    }

    final scoreLineId = preset.enteredLines.first.id;
    final hasMissingValues = participantValues.any(
      (participant) => !participant.enteredValues.containsKey(scoreLineId),
    );

    if (hasMissingValues) {
      throw const QuickScoreValidationException(
        'Enter a score for every player.',
      );
    }

    final completedAt = DateTime.now();
    final resolvedOptions = resolvePresetOptions(
      preset: preset,
      promptAnswers: promptAnswers,
    );
    final result = calculateQuickScoreResult(
      sessionId: sessionId ?? createQuickScoreSessionId(timestamp: completedAt),
      preset: preset,
      completedAt: completedAt,
      winnerRule: resolvedOptions.winnerRule,
      options: resolvedOptions.formulaValues,
      participantValues: participantValues,
    );

    await sessionRepository.saveQuickScoreResult(
      result: result,
      promptAnswers: resolvedOptions.promptAnswers,
      participantValues: participantValues,
    );

    return result;
  }
}

class QuickScoreValidationException implements Exception {
  const QuickScoreValidationException(this.message);

  final String message;
}