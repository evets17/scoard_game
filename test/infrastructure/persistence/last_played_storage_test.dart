import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/application/models/results/round_score_player_result.dart';
import 'package:scoard_game/application/models/scoring/winner_rule.dart';
import 'package:scoard_game/application/models/sessions/quick_score_active_session.dart';
import 'package:scoard_game/application/models/sessions/quick_score_participant_values.dart';
import 'package:scoard_game/infrastructure/persistence/db/app_database.dart';
import 'package:scoard_game/infrastructure/persistence/repositories/persistent_session_repository.dart';

void main() {
  test('last played covers finished games and games in progress', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final repository = PersistentSessionRepository(database);

    Future<void> finishRoundGame(String sessionId, DateTime completedAt) {
      return database.saveRoundScoreResult(
        sessionId: sessionId,
        templateId: 'round-score-basic',
        templateDisplayName: 'Round Score',
        winnerRule: WinnerRule.highestScoreWins.name,
        optionsJson: '[]',
        roundCount: 1,
        completedAt: completedAt,
        rounds: const [],
        playerResults: const [
          RoundScorePlayerResult(
            playerId: 'player-avery',
            displayName: 'Avery',
            cumulativeScore: 5,
            placement: 1,
            isTied: false,
          ),
          RoundScorePlayerResult(
            playerId: 'player-jules',
            displayName: 'Jules',
            cumulativeScore: 3,
            placement: 2,
            isTied: false,
          ),
        ],
      );
    }

    await finishRoundGame('older', DateTime(2026, 10, 1));
    await finishRoundGame('newer', DateTime(2026, 10, 5));
    await repository.saveQuickScoreActiveSession(
      session: QuickScoreActiveSession(
        sessionId: 'in-progress',
        presetId: 'quick-final-score-basic',
        templateDisplayName: 'Quick Score',
        promptAnswers: const [],
        participantValues: const [
          QuickScoreParticipantValues(
            playerId: 'player-jules',
            displayName: 'Jules',
            enteredValues: {'final-score': 0},
          ),
        ],
        updatedAt: DateTime(2026, 10, 9),
      ),
    );

    final lastPlayed = await repository.loadLastPlayedAtByPlayerId();

    expect(lastPlayed['player-avery'], DateTime(2026, 10, 5));
    expect(lastPlayed['player-jules'], DateTime(2026, 10, 9));
    expect(lastPlayed.containsKey('player-mina'), isFalse);

    await database.close();
  });
}
