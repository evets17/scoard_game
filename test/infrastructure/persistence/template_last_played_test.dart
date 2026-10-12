import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/application/models/scoring/winner_rule.dart';
import 'package:scoard_game/application/models/sessions/round_score_active_session.dart';
import 'package:scoard_game/infrastructure/persistence/db/app_database.dart';
import 'package:scoard_game/infrastructure/persistence/repositories/persistent_session_repository.dart';

void main() {
  test('last played per template covers finished and in-progress games', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final repository = PersistentSessionRepository(database);

    Future<void> finishRoundGame(
      String sessionId,
      String templateId,
      DateTime completedAt,
    ) {
      return database.saveRoundScoreResult(
        sessionId: sessionId,
        templateId: templateId,
        templateDisplayName: templateId,
        winnerRule: WinnerRule.highestScoreWins.name,
        optionsJson: '[]',
        roundCount: 0,
        completedAt: completedAt,
        rounds: const [],
        playerResults: const [],
      );
    }

    await finishRoundGame('a', 'skyjo', DateTime(2026, 10, 1));
    await finishRoundGame('b', 'skyjo', DateTime(2026, 10, 4));
    await finishRoundGame('c', 'cornhole', DateTime(2026, 10, 2));
    await repository.saveRoundScoreActiveSession(
      session: RoundScoreActiveSession(
        sessionId: 'in-progress',
        presetId: 'cornhole',
        templateDisplayName: 'Cornhole',
        promptAnswers: const [],
        selectedPlayers: const [],
        savedRounds: const [],
        currentRoundParticipantValues: const [],
        currentRoundNumber: 1,
        updatedAt: DateTime(2026, 10, 8),
      ),
    );

    final lastPlayed = await repository.loadLastPlayedAtByTemplateId();

    expect(lastPlayed['skyjo'], DateTime(2026, 10, 4));
    expect(lastPlayed['cornhole'], DateTime(2026, 10, 8));

    await database.close();
  });
}
