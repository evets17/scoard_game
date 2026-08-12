import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/application/models/results/quick_score_player_result.dart';
import 'package:scoard_game/application/models/scoring/winner_rule.dart';
import 'package:scoard_game/application/models/sessions/quick_score_participant_values.dart';
import 'package:scoard_game/infrastructure/persistence/db/app_database.dart';

void main() {
  test('app database persists quick score field values separately from resolved results', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());

    await database.saveQuickScoreResult(
      sessionId: 'quick-score-test',
      templateId: 'quick-final-score-basic',
      templateDisplayName: 'Quick Score',
      winnerRule: WinnerRule.highestScoreWins.name,
      optionsJson: '[]',
      completedAt: DateTime(2026, 8, 9),
      participantValues: const [
        QuickScoreParticipantValues(
          playerId: 'player-avery',
          displayName: 'Avery',
          enteredValues: {'final-score': 18},
        ),
        QuickScoreParticipantValues(
          playerId: 'player-jules',
          displayName: 'Jules',
          enteredValues: {'final-score': 26},
        ),
      ],
      playerResults: const [
        QuickScorePlayerResult(
          playerId: 'player-jules',
          displayName: 'Jules',
          finalScore: 26,
          placement: 1,
          isTied: false,
        ),
        QuickScorePlayerResult(
          playerId: 'player-avery',
          displayName: 'Avery',
          finalScore: 18,
          placement: 2,
          isTied: false,
        ),
      ],
    );

    final storedFieldValues = await database.loadQuickScoreFieldValues(
      sessionId: 'quick-score-test',
    );
    final storedResults = await database.loadQuickScorePlayerResults(
      sessionId: 'quick-score-test',
    );

    expect(storedFieldValues.length, 2);
    expect(storedFieldValues.first.fieldId, 'final-score');
    expect(storedFieldValues.first.integerValue, 18);
    expect(storedResults.first.finalScore, 26);

    await database.close();
  });
}