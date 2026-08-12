import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_answer.dart';
import 'package:scoard_game/application/models/sessions/quick_score_participant_values.dart';
import 'package:scoard_game/application/models/sessions/round_score_round_values.dart';
import 'package:scoard_game/application/services/sessions/save_round_score_session.dart';
import 'package:scoard_game/bootstrap/app_bootstrap.dart';
import 'package:scoard_game/core/scoring/built_in_templates/round_score_basic_preset.dart';

void main() {
  test('save round score session calculates cumulative totals over multiple rounds', () async {
    final environment = await AppBootstrap.initialize();

    final result = await environment.saveRoundScoreSession(
      preset: roundScoreBasicPreset,
      rounds: const [
        RoundScoreRoundValues(
          roundNumber: 1,
          participantValues: [
            QuickScoreParticipantValues(
              playerId: 'player-avery',
              displayName: 'Avery',
              enteredValues: {roundScoreFieldId: 10},
            ),
            QuickScoreParticipantValues(
              playerId: 'player-jules',
              displayName: 'Jules',
              enteredValues: {roundScoreFieldId: 15},
            ),
          ],
        ),
        RoundScoreRoundValues(
          roundNumber: 2,
          participantValues: [
            QuickScoreParticipantValues(
              playerId: 'player-avery',
              displayName: 'Avery',
              enteredValues: {roundScoreFieldId: 12},
            ),
            QuickScoreParticipantValues(
              playerId: 'player-jules',
              displayName: 'Jules',
              enteredValues: {roundScoreFieldId: 8},
            ),
          ],
        ),
      ],
    );

    expect(result.roundCount, 2);
    expect(result.playerResults.first.displayName, 'Jules');
    expect(result.playerResults.first.cumulativeScore, 23);
    expect(result.playerResults.first.placement, 1);
    expect(result.playerResults[1].displayName, 'Avery');
    expect(result.playerResults[1].cumulativeScore, 22);
  });

  test('save round score session requires at least one round', () async {
    final environment = await AppBootstrap.initialize();

    expect(
      () => environment.saveRoundScoreSession(
        preset: roundScoreBasicPreset,
        rounds: const [],
      ),
      throwsA(isA<RoundScoreValidationException>()),
    );
  });

  test('save round score session supports low score wins from prompted options', () async {
    final environment = await AppBootstrap.initialize();

    final result = await environment.saveRoundScoreSession(
      preset: roundScoreBasicPreset,
      promptAnswers: const [
        PresetPromptAnswer.boolean(id: 'low-score-wins', value: true),
      ],
      rounds: const [
        RoundScoreRoundValues(
          roundNumber: 1,
          participantValues: [
            QuickScoreParticipantValues(
              playerId: 'player-avery',
              displayName: 'Avery',
              enteredValues: {roundScoreFieldId: 18},
            ),
            QuickScoreParticipantValues(
              playerId: 'player-jules',
              displayName: 'Jules',
              enteredValues: {roundScoreFieldId: 12},
            ),
          ],
        ),
      ],
    );

    expect(result.winnerRule.name, 'lowestScoreWins');
    expect(result.playerResults.first.displayName, 'Jules');
    expect(result.playerResults.first.placement, 1);
  });
}