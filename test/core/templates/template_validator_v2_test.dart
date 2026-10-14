import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/core/templates/template_catalog.dart';
import 'package:scoard_game/core/templates/template_validator.dart';

Map<String, Object?> versionTwo({
  required List<Map<String, Object?>> fields,
  String score = 'scored',
}) {
  return {
    'schemaVersion': 2,
    'id': 'test-game',
    'version': '1.0.0',
    'name': 'Test Game',
    'description': 'x',
    'players': {'minimum': 2},
    'scoringModel': 'rounds',
    'winner': 'highestScore',
    'fields': fields,
    'score': score,
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

  test('a good version 2 template has no problems and parses', () {
    final template = versionTwo(
      fields: [
        entered,
        calculated('scored', 'max(0, {points} - highestOther(points))'),
      ],
    );

    expect(problemsFor(template), isEmpty);

    final preset = loadTemplateCatalog({
      'test-game.json': jsonEncode(template),
    }).catalog.byId('test-game');
    expect(preset.scoreFields.single.id, 'points');
    expect(preset.calculatedFields.single.id, 'scored');
    expect(preset.scoreId, 'scored');
  });

  test('version 2 uses fields and score, not scoreField', () {
    final template = versionTwo(fields: [entered], score: 'points')
      ..['scoreField'] = entered;

    expect(problemsFor(template), contains('scoreField: unknown key'));
  });

  test('formula syntax errors give the field and position', () {
    final problems = problemsFor(
      versionTwo(fields: [entered, calculated('scored', 'max(0, {points}')]),
    );

    expect(
      problems,
      ['fields[1].formula: expected ")" but found the end at position 16'],
    );
  });

  test('formula names are checked against the template\'s fields', () {
    final problems = problemsFor(
      versionTwo(
        fields: [entered, calculated('scored', '{bonus} + highestOther(points)')],
      ),
    );

    expect(
      problems.single,
      startsWith('fields[1].formula: unknown name "bonus"'),
    );
  });

  test('circular references are reported once with the loop', () {
    final problems = problemsFor(
      versionTwo(
        fields: [
          entered,
          calculated('scored', '{subtotal} + 1'),
          calculated('subtotal', '{scored} * 2'),
        ],
      ),
    );

    expect(
      problems,
      ['fields[1].formula: circular reference: scored -> subtotal -> scored'],
    );
  });

  test('exactly one entered field, unique ids, and a real score', () {
    final problems = problemsFor(
      versionTwo(
        fields: [
          entered,
          {'id': 'points', 'label': 'Again'},
        ],
        score: 'total',
      ),
    );

    expect(
      problems,
      containsAll([
        'fields[1].id: duplicate field id "points"',
        'fields: needs exactly one entered field (a field without a formula); found 2',
        'score: "total" is not one of the fields: points',
      ]),
    );
  });

  test('marker fields are checked and readable by formulas', () {
    final good = versionTwo(
      fields: [
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
      versionTwo(
        fields: [
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
        'fields[1].marker.badge: must be at most 8 characters',
        'fields[1].marker.color: "blue" must look like #3A7BD5',
        'fields[1].marker.size: unknown key',
        'fields[2].marker.badge: is required',
      ]),
    );
    // Markers do not count as the one entered number field.
    expect(problems.where((p) => p.startsWith('fields:')), isEmpty);
  });

  test('score notes read fields, prompts, and tile groups', () {
    final template = versionTwo(
      fields: [
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
      ..['scoreNotes'] = [
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
    expect(preset.scoreNotes.map((note) => note.text), ['Bonus! from {points}', '×2']);
  });

  test('score note mistakes are reported', () {
    final template = versionTwo(
      fields: [entered, calculated('scored', '{points}')],
    )..['scoreNotes'] = [
        {'when': '{nope} > 0', 'text': 'from {missing}', 'color': 'green'},
        {'text': 'This note is far too long to fit under a score'},
      ];

    expect(problemsFor(template), [
      'scoreNotes[0].text: unknown name "{missing}"; expected one of: '
          'points, scored, playerCount, roundNumber',
      'scoreNotes[0].color: "green" must look like #3A7BD5',
      startsWith('scoreNotes[0].when: unknown name "nope"'),
      'scoreNotes[1].text: must be at most 24 characters',
      'scoreNotes[1].when: is required',
    ]);
  });

  test('a tile group may not share a name that notes read', () {
    final template = versionTwo(
      fields: [
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
    )..['scoreNotes'] = [
        {'when': '{scored} > 0', 'text': 'Scored'},
      ];

    expect(
      problemsFor(template),
      contains(startsWith('scoreNotes: tile group "scored" has the same name')),
    );
  });

  test('formulas can read prompts, and fields cannot reuse their ids', () {
    final template = versionTwo(
      fields: [entered, calculated('scored', '{points} * if({double}, 2, 1)')],
    )..['prompts'] = [
        {'id': 'double', 'type': 'boolean', 'label': 'Double'},
      ];
    expect(problemsFor(template), isEmpty);

    final clash = versionTwo(
      fields: [entered, calculated('double', '{points}')],
      score: 'double',
    )..['prompts'] = [
        {'id': 'double', 'type': 'boolean', 'label': 'Double'},
      ];
    expect(
      problemsFor(clash),
      ['fields[1].id: "double" is already the name of a prompt or built-in value'],
    );
  });
}
