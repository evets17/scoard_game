import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/application/models/results/round_score_player_result.dart';
import 'package:scoard_game/application/models/scoring/winner_rule.dart';
import 'package:scoard_game/application/models/sessions/quick_score_participant_values.dart';
import 'package:scoard_game/application/models/sessions/round_score_round_values.dart';
import 'package:scoard_game/infrastructure/persistence/db/app_database.dart';

void main() {
  test('app database persists round score values separately from cumulative results', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());

    await database.saveRoundScoreResult(
      sessionId: 'round-score-test',
      templateId: 'round-score-basic',
      templateDisplayName: 'Round Score',
      winnerRule: WinnerRule.highestScoreWins.name,
      optionsJson: '[]',
      roundCount: 2,
      completedAt: DateTime(2026, 8, 10),
      rounds: const [
        RoundScoreRoundValues(
          roundNumber: 1,
          participantValues: [
            QuickScoreParticipantValues(
              playerId: 'player-avery',
              displayName: 'Avery',
              enteredValues: {'round-score': 10},
            ),
            QuickScoreParticipantValues(
              playerId: 'player-jules',
              displayName: 'Jules',
              enteredValues: {'round-score': 15},
            ),
          ],
        ),
        RoundScoreRoundValues(
          roundNumber: 2,
          participantValues: [
            QuickScoreParticipantValues(
              playerId: 'player-avery',
              displayName: 'Avery',
              enteredValues: {'round-score': 12},
            ),
            QuickScoreParticipantValues(
              playerId: 'player-jules',
              displayName: 'Jules',
              enteredValues: {'round-score': 8},
            ),
          ],
        ),
      ],
      playerResults: const [
        RoundScorePlayerResult(
          playerId: 'player-jules',
          displayName: 'Jules',
          cumulativeScore: 23,
          placement: 1,
          isTied: false,
        ),
        RoundScorePlayerResult(
          playerId: 'player-avery',
          displayName: 'Avery',
          cumulativeScore: 22,
          placement: 2,
          isTied: false,
        ),
      ],
    );

    final storedFieldValues = await database.loadRoundScoreFieldValues(
      sessionId: 'round-score-test',
    );
    final storedResults = await database.loadRoundScorePlayerResults(
      sessionId: 'round-score-test',
    );

    expect(storedFieldValues.length, 4);
    expect(storedFieldValues.first.roundNumber, 1);
    expect(storedFieldValues.first.fieldId, 'round-score');
    expect(storedFieldValues.first.integerValue, 10);
    expect(storedResults.first.cumulativeScore, 23);

    await database.close();
  });
}