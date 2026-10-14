import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/application/models/scoring/card_text.dart';
import 'package:scoard_game/application/models/scoring/calculated_line_definition.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_definition.dart';
import 'package:scoard_game/application/models/scoring/entered_line_definition.dart';
import 'package:scoard_game/application/models/scoring/score_input_kind.dart';
import 'package:scoard_game/application/models/scoring/scoring_model.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/application/models/scoring/value_picker_pick.dart';
import 'package:scoard_game/application/models/scoring/winner_rule.dart';
import 'package:scoard_game/application/models/sessions/quick_score_participant_values.dart';
import 'package:scoard_game/core/scoring/score_engine.dart';
import 'package:scoard_game/core/templates/template_catalog.dart';

ScoringPreset presetWith({
  List<CalculatedLineDefinition> calculated = const [],
  String? scoreLineId,
  List<PresetPromptDefinition> prompts = const [],
}) {
  return ScoringPreset(
    id: 'engine-test',
    displayName: 'Engine Test',
    description: 'x',
    scoringModel: ScoringModel.rounds,
    minimumPlayers: 2,
    winnerRule: WinnerRule.highestScoreWins,
    enteredLines: const [
      EnteredLineDefinition(
        id: 'points',
        label: 'Points',
        inputKind: ScoreInputKind.integer,
        isEntered: true,
        contributesToFinalResult: true,
      ),
    ],
    calculatedLines: calculated,
    promptDefinitions: prompts,
    scoreLineId: scoreLineId,
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
  test('without calculated lines the entered value is the score', () {
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
          CalculatedLineDefinition(
            id: 'scored',
            label: 'Scored',
            formula: 'max(0, {points} - highestOther(points))',
          ),
        ],
        scoreLineId: 'scored',
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

  test('a line can read another player\'s calculated line', () {
    // "leader" is listed before what it reads, so order must be worked out.
    final engine = ScoreEngine.of(
      presetWith(
        calculated: const [
          CalculatedLineDefinition(
            id: 'leader',
            label: 'Leader',
            formula: 'if({doubled} > highestOther(doubled), 1, 0)',
          ),
          CalculatedLineDefinition(
            id: 'doubled',
            label: 'Doubled',
            formula: '{points} * 2 + {roundNumber} + {playerCount}',
          ),
        ],
        scoreLineId: 'leader',
      ),
    );

    final values = engine.lineValues(entries({'a': 3, 'b': 5}), roundNumber: 4);

    expect(values['a'], {'points': 3, 'doubled': 12, 'leader': 0});
    expect(values['b'], {'points': 5, 'doubled': 16, 'leader': 1});
  });

  test('formulas read prompt answers passed as options', () {
    final engine = ScoreEngine.of(
      presetWith(
        calculated: const [
          CalculatedLineDefinition(
            id: 'scored',
            label: 'Scored',
            formula: '{points} * if({double} > 0, 2, 1)',
          ),
        ],
        scoreLineId: 'scored',
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

  test('card text reads tiles, lines, other players, prompts, and seats', () {
    final preset = loadTemplateCatalog({
      'cards.json': jsonEncode({
        'schemaVersion': 1,
        'id': 'cards',
        'version': '1.0.0',
        'name': 'Cards',
        'description': 'x',
        'players': {'minimum': 2},
        'scoringModel': 'rounds',
        'winner': 'highestScore',
        'prompts': [
          {'id': 'bonus-note', 'type': 'boolean', 'label': 'Bonus note'},
        ],
        'lines': [
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
        'scoreLabels': [
          {'when': '{points} == 0', 'text': 'Zero', 'size': 'small'},
        ],
        'scoreSubLabels': [
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
        'playerBadges': [
          {'when': '{bonus} > 0', 'text': 'Bonus'},
          {
            'when': '({roundNumber} - 1) % {playerCount} + 1 == '
                '{playerPosition}',
            'text': '1st',
          },
        ],
      }),
    }).catalog.byId('cards');
    final engine = ScoreEngine.of(preset);

    // In play order: a sits first, b second, c third.
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
      const QuickScoreParticipantValues(
        playerId: 'c',
        displayName: 'c',
        enteredValues: {'points': 0},
      ),
    ];

    final round1 = engine.cardTexts(
      participants,
      roundNumber: 1,
      options: const {'bonus-note': 1},
    );
    // With the option on, the tile sub label comes first.
    expect(round1['a']!.scoreSubLabel!.text, 'Bonus +10');
    expect(round1['a']!.scoreSubLabel!.color, '#00AA00');
    // Every badge that applies, in template order.
    expect(round1['a']!.playerBadges.map((badge) => badge.text), ['Bonus', '1st']);
    expect(round1['b']!.playerBadges, isEmpty);
    expect(round1['b']!.scoreSubLabel, isNull);
    expect(round1['c']!.scoreLabel!.text, 'Zero');
    expect(round1['c']!.scoreLabel!.size, CardTextSize.small);

    // Without the option the next sub label applies. The first seat moves
    // one along each round and wraps after the last.
    final round5 = engine.cardTexts(
      participants,
      roundNumber: 5,
      options: const {'bonus-note': 0},
    );
    expect(round5['a']!.scoreSubLabel!.text, 'from 11, top');
    expect(round5['a']!.playerBadges.map((badge) => badge.text), ['Bonus']);
    expect(round5['b']!.playerBadges.map((badge) => badge.text), ['1st']);
  });

  test('line order follows dependencies and loops are named', () {
    expect(
      orderCalculatedLines({
        'total': {'subtotal', 'points'},
        'subtotal': {'points'},
      }),
      ['subtotal', 'total'],
    );
    expect(
      () => orderCalculatedLines({
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
