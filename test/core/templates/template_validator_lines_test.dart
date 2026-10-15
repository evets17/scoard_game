import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/application/models/scoring/sheet_layout.dart';
import 'package:scoard_game/core/templates/template_catalog.dart';
import 'package:scoard_game/core/templates/template_validator.dart';

/// A template with these [lines], whose score is [score].
Map<String, Object?> sheet({
  required List<Map<String, Object?>> lines,
  String? score = 'scored',
  String scoringModel = 'rounds',
}) {
  return {
    'schemaVersion': 1,
    'id': 'test-game',
    'version': '1.0.0',
    'name': 'Test Game',
    'description': 'x',
    'players': {'minimum': 2},
    'scoringModel': scoringModel,
    'winner': 'highestScore',
    'lines': lines,
    'score': ?score,
  };
}

const entered = <String, Object?>{'id': 'points', 'label': 'Points'};

Map<String, Object?> calculated(String id, String formula) =>
    {'id': id, 'label': id, 'formula': formula};

void main() {
  List<String> problemsFor(Map<String, Object?> template) {
    return validateTemplateJson(
      jsonDecode(jsonEncode(template)),
      expectedId: 'test-game',
    ).map((problem) => problem.toString()).toList();
  }

  test('a good score sheet has no problems and parses', () {
    final template = sheet(
      lines: [
        entered,
        calculated('scored', 'max(0, {points} - highestOther(points))'),
      ],
    );

    expect(problemsFor(template), isEmpty);

    final preset = loadTemplateCatalog({
      'test-game.json': jsonEncode(template),
    }).catalog.byId('test-game');
    expect(preset.enteredLines.single.id, 'points');
    expect(preset.calculatedLines.single.id, 'scored');
    expect(preset.scoreId, 'scored');
  });

  test('the old scoreField and fields shapes are gone', () {
    final template = sheet(lines: [entered], score: 'points')
      ..['scoreField'] = entered
      ..['fields'] = [entered];

    expect(
      problemsFor(template),
      containsAll(['scoreField: unknown key', 'fields: unknown key']),
    );
  });

  test('score can be left out when the one entered line is the score', () {
    final template = sheet(lines: [entered], score: null);

    expect(problemsFor(template), isEmpty);
    final preset = loadTemplateCatalog({
      'test-game.json': jsonEncode(template),
    }).catalog.byId('test-game');
    expect(preset.scoreId, 'points');
  });

  test('formula syntax errors give the line and position', () {
    final problems = problemsFor(
      sheet(lines: [entered, calculated('scored', 'max(0, {points}')]),
    );

    expect(
      problems,
      ['lines[1].formula: expected ")" but found the end at position 16'],
    );
  });

  test('formula names are checked against the template\'s lines', () {
    final problems = problemsFor(
      sheet(
        lines: [entered, calculated('scored', '{bonus} + highestOther(points)')],
      ),
    );

    expect(
      problems.single,
      startsWith('lines[1].formula: unknown name "bonus"'),
    );
  });

  test('circular references are reported once with the loop', () {
    final problems = problemsFor(
      sheet(
        lines: [
          entered,
          calculated('scored', '{subtotal} + 1'),
          calculated('subtotal', '{scored} * 2'),
        ],
      ),
    );

    expect(
      problems,
      ['lines[1].formula: circular reference: scored -> subtotal -> scored'],
    );
  });

  test('at least one entered line, unique ids, and a real score', () {
    final problems = problemsFor(
      sheet(
        lines: [
          entered,
          {'id': 'points', 'label': 'Again'},
        ],
        score: 'total',
      ),
    );

    expect(
      problems,
      containsAll([
        'lines[1].id: duplicate line id "points"',
        'score: "total" is not one of the lines: points',
      ]),
    );
    expect(
      problemsFor(sheet(lines: [calculated('scored', '1')])),
      contains(
        'lines: needs at least one entered line (a line without a formula or marker)',
      ),
    );
  });

  test('several entered lines in sections, with row styles', () {
    final template = sheet(
      lines: [
        {'heading': 'Wildlife'},
        {'id': 'bear', 'label': 'Bear'},
        {'id': 'elk', 'label': 'Elk'},
        {
          'id': 'wildlife',
          'label': 'Wildlife',
          'formula': '{bear} + {elk}',
          'style': {'bold': true, 'ruleAbove': true},
        },
        {
          'heading': 'Nature tokens',
          'style': {'shade': '#2E7D32'},
        },
        {'id': 'tokens', 'label': 'Tokens'},
        calculated('total', '{wildlife} + {tokens}'),
      ],
      score: 'total',
      scoringModel: 'finalScore',
    )..['entryOrder'] = 'byPlayer';
    expect(problemsFor(template), isEmpty);

    final preset = loadTemplateCatalog({
      'test-game.json': jsonEncode(template),
    }).catalog.byId('test-game');
    expect(preset.enteredLines.map((line) => line.id), ['bear', 'elk', 'tokens']);
    expect(
      [
        for (final item in preset.sheetLayout)
          item.heading ?? item.lineId,
      ],
      ['Wildlife', 'bear', 'elk', 'wildlife', 'Nature tokens', 'tokens', 'total'],
    );
    final styles = {
      for (final item in preset.sheetLayout) item.heading ?? item.lineId: item.style,
    };
    expect(styles['wildlife']!.bold, isTrue);
    expect(styles['wildlife']!.ruleAbove, isTrue);
    expect(styles['Nature tokens']!.shade, '#2E7D32');
    expect(styles['bear']!.shade, isNull);
    expect(preset.entryOrder, SheetEntryOrder.byPlayer);
  });

  test('several entered lines are for finalScore games only, so far', () {
    final problems = problemsFor(
      sheet(
        lines: [
          {'id': 'bear', 'label': 'Bear'},
          {'id': 'elk', 'label': 'Elk'},
          calculated('scored', '{bear} + {elk}'),
        ],
      ),
    );

    expect(
      problems,
      [
        'lines: several entered lines are only supported for finalScore '
            'games so far',
      ],
    );
  });

  test('headings need lines, several entered lines need a score', () {
    final problems = problemsFor(
      sheet(
        lines: [
          {'heading': 'Empty'},
          {'heading': 'Wildlife', 'note': 'x'},
          {
            'id': 'bear',
            'label': 'Bear',
            'subtotal': true,
            'style': {'shade': 'green', 'bold': 'yes', 'size': 2},
          },
          {'id': 'elk', 'label': 'Elk'},
          {'heading': ''},
        ],
        score: null,
        scoringModel: 'finalScore',
      )..['entryOrder'] = 'sideways',
    );

    expect(
      problems,
      containsAll([
        'lines[0].heading: needs at least one line after it',
        'lines[1].note: unknown key',
        'lines[2].subtotal: unknown key',
        'lines[2].style.size: unknown key',
        'lines[2].style.shade: "green" must look like #3A7BD5',
        'lines[2].style.bold: must be true or false',
        'lines[4].heading: must not be empty',
        'score: is required when there are several entered lines',
        startsWith('entryOrder: unsupported value "sideways"'),
      ]),
    );
  });

  test('marker lines are checked and readable by formulas', () {
    final good = sheet(
      lines: [
        entered,
        {
          'id': 'first-out',
          'label': 'Went out first',
          'marker': {'badge': 'Out', 'color': '#1565C0', 'onePerRound': true},
        },
        calculated('scored', 'if({first-out} > 0, {points} * 2, {points})'),
      ],
    );
    expect(problemsFor(good), isEmpty);

    final problems = problemsFor(
      sheet(
        lines: [
          entered,
          {
            'id': 'flag',
            'label': 'Flag',
            'marker': {'badge': 'Way too long', 'color': 'blue', 'size': 1},
          },
          {'id': 'empty', 'label': 'Empty', 'marker': <String, Object?>{}},
          calculated('scored', '{points}'),
        ],
      ),
    );

    expect(
      problems,
      containsAll([
        'lines[1].marker.badge: must be at most 8 characters',
        'lines[1].marker.color: "blue" must look like #3A7BD5',
        'lines[1].marker.size: unknown key',
        'lines[2].marker.badge: is required',
      ]),
    );
    // Markers do not count as the one entered number line.
    expect(problems.where((p) => p.startsWith('lines:')), isEmpty);
  });

  test('card text reads lines, prompts, and tile groups', () {
    final template = sheet(
      lines: [
        {
          ...entered,
          'entry': {'tapToEdit': true},
          'entryModes': [
            {
              'type': 'valuePicker',
              'id': 'cards',
              'label': 'Cards',
              'groups': [
                {
                  'id': 'bonus',
                  'values': [
                    {'value': 5, 'text': 'Bonus'},
                  ],
                },
              ],
            },
          ],
        },
        calculated('scored', '{points} * 2'),
      ],
    )
      ..['prompts'] = [
        {'id': 'double', 'type': 'boolean', 'label': 'Double'},
      ]
      ..['scoreSubLabels'] = [
        {
          'when': '{bonus} > 0 and {scored} > highestOther(scored)',
          'text': 'Bonus! from {points}',
          'color': '#00AA00',
        },
        {'when': '{double} and countIn(bonus) == 0', 'text': '×2'},
      ];
    expect(problemsFor(template), isEmpty);

    final preset = loadTemplateCatalog({
      'test-game.json': jsonEncode(template),
    }).catalog.byId('test-game');
    expect(
      preset.scoreSubLabels.map((subLabel) => subLabel.text),
      ['Bonus! from {points}', '×2'],
    );
  });

  test('card text mistakes are reported', () {
    final template = sheet(
      lines: [entered, calculated('scored', '{points}')],
    )..['scoreSubLabels'] = [
        {'when': '{nope} > 0', 'text': 'from {missing}', 'color': 'green'},
        {'text': 'This note is far too long to fit under a score'},
      ];

    expect(problemsFor(template), [
      'scoreSubLabels[0].text: unknown name "{missing}"; expected one of: '
          'points, scored, playerCount, roundNumber, playerPosition',
      'scoreSubLabels[0].color: "green" must look like #3A7BD5',
      startsWith('scoreSubLabels[0].when: unknown name "nope"'),
      'scoreSubLabels[1].text: must be at most 24 characters',
      'scoreSubLabels[1].when: is required',
    ]);
  });

  test('a tile group may not share a name that card text reads', () {
    final template = sheet(
      lines: [
        {
          ...entered,
          'entry': {'tapToEdit': true},
          'entryModes': [
            {
              'type': 'valuePicker',
              'id': 'cards',
              'label': 'Cards',
              'groups': [
                {
                  'id': 'scored',
                  'values': [
                    {'value': 1},
                  ],
                },
              ],
            },
          ],
        },
        calculated('scored', '{points}'),
      ],
    )..['scoreSubLabels'] = [
        {'when': '{scored} > 0', 'text': 'Scored'},
      ];

    expect(
      problemsFor(template),
      contains(startsWith('scoreSubLabels: tile group "scored" has the same name')),
    );
  });

  test('formulas can read prompts, and lines cannot reuse their ids', () {
    final template = sheet(
      lines: [entered, calculated('scored', '{points} * if({double}, 2, 1)')],
    )..['prompts'] = [
        {'id': 'double', 'type': 'boolean', 'label': 'Double'},
      ];
    expect(problemsFor(template), isEmpty);

    final clash = sheet(
      lines: [entered, calculated('double', '{points}')],
      score: 'double',
    )..['prompts'] = [
        {'id': 'double', 'type': 'boolean', 'label': 'Double'},
      ];
    expect(
      problemsFor(clash),
      ['lines[1].id: "double" is already the name of a prompt or built-in value'],
    );
  });

  test('line pictures and what labels show', () {
    final template = sheet(
      lines: [
        {'id': 'bear', 'label': 'Bear', 'image': 'cascadia_bear.png'},
        {
          'id': 'bear-bonus',
          'label': '+',
          'image': 'cascadia_bear.png',
          'style': {'label': 'imageAndText'},
        },
        calculated('scored', '{bear} + {bear-bonus}'),
      ],
      scoringModel: 'finalScore',
    )..['lineLabels'] = 'image';
    expect(problemsFor(template), isEmpty);

    final preset = loadTemplateCatalog({
      'test-game.json': jsonEncode(template),
    }).catalog.byId('test-game');
    expect(preset.lineLabels, LineLabelDisplay.image);
    expect(preset.lineImages, {'cascadia_bear.png'});
    final bonus =
        preset.sheetLayout.firstWhere((item) => item.lineId == 'bear-bonus');
    expect(bonus.style.label, LineLabelDisplay.imageAndText);

    final bad = sheet(
      lines: [
        {'heading': 'Wildlife', 'image': 'cascadia_bear.png'},
        {'id': 'bear', 'label': 'Bear', 'image': '../secret.png'},
        {
          'id': 'elk',
          'label': 'Elk',
          'image': 'Elk.GIF',
          'style': {'label': 'picture'},
        },
        calculated('scored', '{bear} + {elk}'),
      ],
      scoringModel: 'finalScore',
    )..['lineLabels'] = 'icons';
    expect(
      problemsFor(bad),
      containsAll([
        startsWith('lineLabels: unsupported value "icons"'),
        'lines[0].image: unknown key',
        startsWith('lines[1].image: "../secret.png" must be a file name'),
        startsWith('lines[2].image: "Elk.GIF" must be a file name'),
        startsWith('lines[2].style.label: unsupported value "picture"'),
      ]),
    );
  });
}
