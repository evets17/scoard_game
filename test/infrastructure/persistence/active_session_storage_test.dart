import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/application/models/app_summaries.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_answer.dart';
import 'package:scoard_game/application/models/sessions/quick_score_active_session.dart';
import 'package:scoard_game/application/models/sessions/quick_score_available_player.dart';
import 'package:scoard_game/application/models/sessions/quick_score_participant_values.dart';
import 'package:scoard_game/application/models/sessions/round_score_active_session.dart';
import 'package:scoard_game/application/models/sessions/round_score_round_values.dart';
import 'package:scoard_game/infrastructure/persistence/db/app_database.dart';
import 'package:scoard_game/infrastructure/persistence/repositories/persistent_session_repository.dart';

void main() {
  test('persistent session repository stores and loads quick score active sessions', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final repository = PersistentSessionRepository(database);

    await repository.saveQuickScoreActiveSession(
      session: QuickScoreActiveSession(
        sessionId: 'quick-draft-1',
        presetId: 'quick-final-score-basic',
        templateDisplayName: 'Quick Score',
        promptAnswers: const [
          PresetPromptAnswer.boolean(id: 'low-score-wins', value: true),
        ],
        participantValues: const [
          QuickScoreParticipantValues(
            playerId: 'player-avery',
            displayName: 'Avery',
            enteredValues: {'final-score': 0},
          ),
          QuickScoreParticipantValues(
            playerId: 'player-jules',
            displayName: 'Jules',
            enteredValues: {'final-score': 12},
          ),
        ],
        updatedAt: DateTime(2026, 8, 11, 9, 0),
      ),
    );

    final summaries = await repository.loadActiveSessions(limit: 10);
    final activeSession = await repository.loadQuickScoreActiveSession(
      sessionId: 'quick-draft-1',
    );

    expect(summaries.single.kind, ActiveSessionKind.quickScore);
    expect(summaries.single.gameName, 'Quick Score');
    expect(summaries.single.progressLabel, '2 players ready');
    expect(activeSession?.promptAnswers.single.booleanValue, true);
    expect(activeSession?.participantValues.first.enteredValues['final-score'], 0);

    await database.close();
  });

  test('persistent session repository stores and loads round score active sessions', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final repository = PersistentSessionRepository(database);

    await repository.saveRoundScoreActiveSession(
      session: RoundScoreActiveSession(
        sessionId: 'round-draft-1',
        presetId: 'round-score-basic',
        templateDisplayName: 'Round Score',
        promptAnswers: const [
          PresetPromptAnswer.boolean(id: 'low-score-wins', value: false),
        ],
        selectedPlayers: const [
          QuickScoreAvailablePlayer(id: 'player-avery', displayName: 'Avery'),
          QuickScoreAvailablePlayer(id: 'player-jules', displayName: 'Jules'),
        ],
        savedRounds: const [
          RoundScoreRoundValues(
            roundNumber: 1,
            participantValues: [
              QuickScoreParticipantValues(
                playerId: 'player-avery',
                displayName: 'Avery',
                enteredValues: {'round-score': 4},
              ),
              QuickScoreParticipantValues(
                playerId: 'player-jules',
                displayName: 'Jules',
                enteredValues: {'round-score': 7},
              ),
            ],
          ),
        ],
        currentRoundParticipantValues: const [
          QuickScoreParticipantValues(
            playerId: 'player-avery',
            displayName: 'Avery',
            enteredValues: {'round-score': 0},
          ),
          QuickScoreParticipantValues(
            playerId: 'player-jules',
            displayName: 'Jules',
            enteredValues: {'round-score': 0},
          ),
        ],
        currentRoundNumber: 2,
        updatedAt: DateTime(2026, 8, 11, 9, 30),
      ),
    );

    final summaries = await repository.loadActiveSessions(limit: 10);
    final activeSession = await repository.loadRoundScoreActiveSession(
      sessionId: 'round-draft-1',
    );

    expect(summaries.single.kind, ActiveSessionKind.roundScore);
    expect(summaries.single.progressLabel, 'Round 2');
    expect(activeSession?.promptAnswers.single.booleanValue, false);
    expect(activeSession?.currentRoundNumber, 2);
    expect(activeSession?.savedRounds.length, 1);

    await database.close();
  });
}