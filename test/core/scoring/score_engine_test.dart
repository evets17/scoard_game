import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/application/models/scoring/calculated_field_definition.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_definition.dart';
import 'package:scoard_game/application/models/scoring/score_field_definition.dart';
import 'package:scoard_game/application/models/scoring/score_input_kind.dart';
import 'package:scoard_game/application/models/scoring/scoring_model.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/application/models/scoring/value_picker_pick.dart';
import 'package:scoard_game/application/models/scoring/winner_rule.dart';
import 'package:scoard_game/application/models/sessions/quick_score_participant_values.dart';
import 'package:scoard_game/core/scoring/score_engine.dart';
import 'package:scoard_game/core/templates/template_catalog.dart';

ScoringPreset presetWith({
  List<CalculatedFieldDefinition> calculated = const [],
  String? scoreFieldId,
  List<PresetPromptDefinition> prompts = const [],
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
    promptDefinitions: prompts,
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

  test('formulas read prompt answers passed as options', () {
    final engine = ScoreEngine.of(
      presetWith(
        calculated: const [
          CalculatedFieldDefinition(
            id: 'scored',
            label: 'Scored',
            formula: '{points} * if({double} > 0, 2, 1)',
          ),
        ],
        scoreFieldId: 'scored',
        prompts: const [
          PresetPromptDefinition.boolean(id: 'double', label: 'Double'),
        ],
      ),
    );

    expect(
      engine.scores(entries({'a': 3}), roundNumber: 1, options: {'double': 1}),
      {'a': 6},
    );
    expect(
      engine.scores(entries({'a': 3}), roundNumber: 1, options: {'double': 0}),
      {'a': 3},
    );
  });

  test('score notes read tiles, fields, other players, and prompts', () {
    final preset = loadTemplateCatalog({
      'notes.json': jsonEncode({
        'schemaVersion': 2,
        'id': 'notes',
        'version': '1.0.0',
        'name': 'Notes',
        'description': 'x',
        'players': {'minimum': 2},
        'scoringModel': 'rounds',
        'winner': 'highestScore',
        'prompts': [
          {'id': 'bonus-note', 'type': 'boolean', 'label': 'Bonus note'},
        ],
        'fields': [
          {
            'id': 'points',
            'label': 'Points',
            'entry': {'tapToEdit': true},
            'entryModes': [
              {
                'type': 'valuePicker',
                'id': 'cards',
                'label': 'Cards',
                'groups': [
                  {
                    'id': 'numbers',
                    'values': [
                      {'value': 1},
                      {'value': 2},
                    ],
                  },
                  {
                    'id': 'bonus',
                    'values': [
                      {'value': 10, 'text': 'Bonus'},
                    ],
                  },
                ],
              },
            ],
          },
          {'id': 'scored', 'label': 'Scored', 'formula': '{points} * 2'},
        ],
        'score': 'scored',
        'scoreNotes': [
          {
            'when': '{bonus} > 0 and {bonus-note}',
            'text': 'Bonus +{bonus}',
            'color': '#00AA00',
          },
          {
            'when': '{scored} > highestOther(scored)',
            'text': 'from {points}, top',
          },
        ],
      }),
    }).catalog.byId('notes');
    final engine = ScoreEngine.of(preset);

    final participants = [
      QuickScoreParticipantValues(
        playerId: 'a',
        displayName: 'a',
        enteredValues: const {'points': 11},
        entryPicks: const {
          'points': ValuePickerPick(pickerId: 'cards', tiles: ['1', 'Bonus']),
        },
      ),
      const QuickScoreParticipantValues(
        playerId: 'b',
        displayName: 'b',
        enteredValues: {'points': 2},
      ),
    ];

    // With the option on, the tile note comes first.
    final withOption = engine.scoreNotes(
      participants,
      roundNumber: 1,
      options: const {'bonus-note': 1},
    );
    expect(withOption.keys, ['a']);
    expect(withOption['a']!.text, 'Bonus +10');
    expect(withOption['a']!.color, '#00AA00');

    // Without it, the next note that applies is used; b has none.
    final withoutOption = engine.scoreNotes(
      participants,
      roundNumber: 1,
      options: const {'bonus-note': 0},
    );
    expect(
      {for (final entry in withoutOption.entries) entry.key: entry.value.text},
      {'a': 'from 11, top'},
    );
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
