import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/application/models/sessions/quick_score_participant_values.dart';
import 'package:scoard_game/application/services/sessions/save_quick_score_session.dart';
import 'package:scoard_game/bootstrap/app_bootstrap.dart';
import 'package:scoard_game/core/scoring/built_in_templates/quick_final_score_basic_preset.dart';

void main() {
  test('save quick score session ranks players and persists a summary', () async {
    final environment = await AppBootstrap.initialize();

    final result = await environment.saveQuickScoreSession(
      preset: quickFinalScoreBasicPreset,
      participantValues: const [
        QuickScoreParticipantValues(
          playerId: 'player-avery',
          displayName: 'Avery',
          enteredValues: {finalScoreFieldId: 18},
        ),
        QuickScoreParticipantValues(
          playerId: 'player-jules',
          displayName: 'Jules',
          enteredValues: {finalScoreFieldId: 26},
        ),
        QuickScoreParticipantValues(
          playerId: 'player-mina',
          displayName: 'Mina',
          enteredValues: {finalScoreFieldId: 26},
        ),
      ],
    );

    expect(result.playerResults.first.displayName, 'Jules');
    expect(result.playerResults.first.placement, 1);
    expect(result.playerResults[1].displayName, 'Mina');
    expect(result.playerResults[1].placement, 1);
    expect(result.playerResults[2].placement, 3);

    final recentSessions = await environment.sessionRepository.loadRecentSessions();
    expect(recentSessions.first.gameName, 'Quick Score');
  });

  test('save quick score session requires at least two players', () async {
    final environment = await AppBootstrap.initialize();

    expect(
      () => environment.saveQuickScoreSession(
        preset: quickFinalScoreBasicPreset,
        participantValues: const [
          QuickScoreParticipantValues(
            playerId: 'player-avery',
            displayName: 'Avery',
            enteredValues: {finalScoreFieldId: 18},
          ),
        ],
      ),
      throwsA(isA<QuickScoreValidationException>()),
    );
  });

  test('saving with the same quick score session id updates the existing result', () async {
    final environment = await AppBootstrap.initialize();

    final firstResult = await environment.saveQuickScoreSession(
      preset: quickFinalScoreBasicPreset,
      participantValues: const [
        QuickScoreParticipantValues(
          playerId: 'player-avery',
          displayName: 'Avery',
          enteredValues: {finalScoreFieldId: 10},
        ),
        QuickScoreParticipantValues(
          playerId: 'player-jules',
          displayName: 'Jules',
          enteredValues: {finalScoreFieldId: 12},
        ),
      ],
    );

    final updatedResult = await environment.saveQuickScoreSession(
      preset: quickFinalScoreBasicPreset,
      sessionId: firstResult.sessionId,
      participantValues: const [
        QuickScoreParticipantValues(
          playerId: 'player-avery',
          displayName: 'Avery',
          enteredValues: {finalScoreFieldId: 18},
        ),
        QuickScoreParticipantValues(
          playerId: 'player-jules',
          displayName: 'Jules',
          enteredValues: {finalScoreFieldId: 12},
        ),
      ],
    );

    expect(updatedResult.sessionId, firstResult.sessionId);

    final recentSessions = await environment.sessionRepository.loadRecentSessions();
    final matchingSessions = recentSessions.where((session) => session.id == firstResult.sessionId).toList(growable: false);

    expect(matchingSessions.length, 1);
    expect(matchingSessions.single.outcomeSummary, 'Avery won with 18.');
  });
}