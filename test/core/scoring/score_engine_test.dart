import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/application/models/scoring/calculated_field_definition.dart';
import 'package:scoard_game/application/models/scoring/score_field_definition.dart';
import 'package:scoard_game/application/models/scoring/score_input_kind.dart';
import 'package:scoard_game/application/models/scoring/scoring_model.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/application/models/scoring/winner_rule.dart';
import 'package:scoard_game/application/models/sessions/quick_score_participant_values.dart';
import 'package:scoard_game/core/scoring/score_engine.dart';

ScoringPreset presetWith({
  List<CalculatedFieldDefinition> calculated = const [],
  String? scoreFieldId,
}) {
  return ScoringPreset(
    id: 'engine-test',
    displayName: 'Engine Test',
    description: 'x',
    scoringModel: ScoringModel.rounds,
    minimumPlayers: 2,
    winnerRule: WinnerRule.highestScoreWins,
    scoreFields: const [
      ScoreFieldDefinition(
        id: 'points',
        label: 'Points',
        inputKind: ScoreInputKind.integer,
        isEntered: true,
        contributesToFinalResult: true,
      ),
    ],
    calculatedFields: calculated,
    scoreFieldId: scoreFieldId,
  );
}

List<QuickScoreParticipantValues> entries(Map<String, int> pointsByPlayer) => [
      for (final entry in pointsByPlayer.entries)
        QuickScoreParticipantValues(
          playerId: entry.key,
          displayName: entry.key,
          enteredValues: {'points': entry.value},
        ),
    ];

void main() {
  test('without calculated fields the entered value is the score', () {
    final engine = ScoreEngine.of(presetWith());

    expect(
      engine.scores(entries({'a': 7, 'b': -2}), roundNumber: 1),
      {'a': 7, 'b': -2},
    );
  });

  test('cancellation scoring reads the other players', () {
    final engine = ScoreEngine.of(
      presetWith(
        calculated: const [
          CalculatedFieldDefinition(
            id: 'scored',
            label: 'Scored',
            formula: 'max(0, {points} - highestOther(points))',
          ),
        ],
        scoreFieldId: 'scored',
      ),
    );

    expect(
      engine.scores(entries({'a': 7, 'b': 4}), roundNumber: 1),
      {'a': 3, 'b': 0},
    );
    expect(
      engine.scores(entries({'a': 5, 'b': 5}), roundNumber: 1),
      {'a': 0, 'b': 0},
    );
  });

  test('a field can read another player\'s calculated field', () {
    // "leader" is listed before what it reads, so order must be worked out.
    final engine = ScoreEngine.of(
      presetWith(
        calculated: const [
          CalculatedFieldDefinition(
            id: 'leader',
            label: 'Leader',
            formula: 'if({doubled} > highestOther(doubled), 1, 0)',
          ),
          CalculatedFieldDefinition(
            id: 'doubled',
            label: 'Doubled',
            formula: '{points} * 2 + {roundNumber} + {playerCount}',
          ),
        ],
        scoreFieldId: 'leader',
      ),
    );

    final values = engine.fieldValues(entries({'a': 3, 'b': 5}), roundNumber: 4);

    expect(values['a'], {'points': 3, 'doubled': 12, 'leader': 0});
    expect(values['b'], {'points': 5, 'doubled': 16, 'leader': 1});
  });

  test('field order follows dependencies and loops are named', () {
    expect(
      orderCalculatedFields({
        'total': {'subtotal', 'points'},
        'subtotal': {'points'},
      }),
      ['subtotal', 'total'],
    );
    expect(
      () => orderCalculatedFields({
        'a': {'b'},
        'b': {'c'},
        'c': {'a'},
      }),
      throwsA(
        isA<CircularFormulaError>().having(
          (error) => error.toString(),
          'message',
          'circular reference: a -> b -> c -> a',
        ),
      ),
    );
  });
}
