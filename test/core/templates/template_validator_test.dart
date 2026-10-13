import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/core/templates/template_catalog.dart';
import 'package:scoard_game/core/templates/template_validator.dart';

Map<String, Object?> validTemplate() => {
      'schemaVersion': 1,
      'id': 'skyjo',
      'version': '1.0.0',
      'name': 'Skyjo',
      'description': 'Lowest total wins.',
      'players': <String, Object?>{'minimum': 2, 'maximum': 8},
      'scoringModel': 'rounds',
      'winner': 'lowestScore',
      'prompts': [
        {
          'id': 'low-score-wins',
          'type': 'boolean',
          'label': 'Low Score Wins',
          'default': false,
          'effect': 'lowScoreWins',
        },
      ],
      'scoreField': {
        'id': 'round-score',
        'label': 'Round Score',
        'initialValue': 0,
        'minimumDisplayDigits': 2,
        'entry': <String, Object?>{'tapToEdit': true, 'quickAdjust': true},
      },
    };

void main() {
  List<String> problemsFor(
    void Function(Map<String, Object?> template) change, {
    String expectedId = 'skyjo',
  }) {
    final template = validTemplate();
    change(template);
    // Round-trip through JSON so values have the types jsonDecode produces.
    final decoded = jsonDecode(jsonEncode(template));
    return validateTemplateJson(decoded, expectedId: expectedId)
        .map((problem) => problem.toString())
        .toList();
  }

  Map<String, Object?> child(Map<String, Object?> map, String key) =>
      map[key]! as Map<String, Object?>;

  test('a complete template has no problems', () {
    expect(problemsFor((_) {}), isEmpty);
  });

  test('missing required keys are reported with their paths', () {
    final problems = problemsFor((template) {
      template.remove('name');
      child(template, 'scoreField').remove('label');
      child(template, 'players').remove('minimum');
    });

    expect(
      problems,
      containsAll([
        'name: is required',
        'scoreField.label: is required',
        'players.minimum: is required',
      ]),
    );
  });

  test('unknown keys are rejected at every level', () {
    final problems = problemsFor((template) {
      template['colour'] = 'blue';
      child(child(template, 'scoreField'), 'entry')['tapTo'] = true;
      ((template['prompts']! as List).first as Map<String, Object?>)['hint'] =
          'x';
    });

    expect(
      problems,
      containsAll([
        'colour: unknown key',
        'scoreField.entry.tapTo: unknown key',
        'prompts[0].hint: unknown key',
      ]),
    );
  });

  test('wrong types and unsupported values are rejected', () {
    final problems = problemsFor((template) {
      template['schemaVersion'] = 3;
      template['version'] = 'one';
      template['subtitle'] = '  ';
      template['scoringModel'] = 'categories';
      child(template, 'players')['minimum'] = 1.5;
      child(child(template, 'scoreField'), 'entry')['adjust'] = 'yes';
    });

    expect(
      problems,
      containsAll([
        'schemaVersion: unsupported version 3; expected one of: 1, 2',
        'version: "one" must look like 1.0.0',
        'subtitle: must not be empty',
        'scoringModel: unsupported value "categories"; expected one of: finalScore, rounds',
        'players.minimum: must be a whole number',
        'scoreField.entry.adjust: must be true or false',
      ]),
    );
  });

  test('ids must be well formed and match the file name', () {
    expect(
      problemsFor((template) => template['id'] = 'Sky Jo'),
      contains(
        'id: "Sky Jo" must use lowercase letters, digits, and single hyphens',
      ),
    );
    expect(
      problemsFor((_) {}, expectedId: 'love-letter'),
      contains('id: "skyjo" does not match the file name "love-letter"'),
    );
  });

  test('player counts must make sense', () {
    final problems = problemsFor((template) {
      child(template, 'players')['minimum'] = 4;
      child(template, 'players')['maximum'] = 3;
    });

    expect(
      problems,
      contains('players.maximum: must not be less than minimum (4)'),
    );
  });

  test('prompt rules are checked', () {
    final problems = problemsFor((template) {
      template['prompts'] = [
        {'id': 'target', 'type': 'integer', 'label': 'Target', 'default': true},
        {
          'id': 'target',
          'type': 'integer',
          'label': 'Again',
          'effect': 'lowScoreWins',
        },
        {'id': 'x', 'type': 'boolean', 'label': 'X', 'effect': 'doubleScores'},
      ];
    });

    expect(
      problems,
      containsAll([
        'prompts[0].default: must be a whole number',
        'prompts[1].id: duplicate prompt id "target"',
        'prompts[1].effect: "lowScoreWins" needs a boolean prompt, not integer',
        'prompts[2].effect: unsupported value "doubleScores"; expected one of: lowScoreWins',
      ]),
    );
  });

  test('the catalog reports bad JSON and keeps good files', () {
    final result = loadTemplateCatalog({
      'assets/templates/skyjo.json': jsonEncode(validTemplate()),
      'assets/templates/broken.json': '{ not json',
    });

    expect(result.catalog.templates.map((template) => template.id), ['skyjo']);
    expect(result.problemsByFile.keys, ['assets/templates/broken.json']);
    expect(result.describeProblems(), contains('is not valid JSON'));
  });

  test('value picker entry modes are checked', () {
    final problems = problemsFor((template) {
      child(template, 'scoreField')['entryModes'] = [
        {
          'type': 'valuePicker',
          'id': 'cards',
          'label': 'Cards',
          'values': [
            {'value': 1, 'color': 'red'},
            {'value': 1},
            {'value': 2, 'size': 'big'},
          ],
        },
        {'type': 'slider', 'id': 'cards', 'label': 'More', 'values': []},
        {
          'type': 'valuePicker',
          'id': 'lots',
          'label': 'Lots',
          'values': [
            for (var value = 0; value < 25; value++) {'value': value},
          ],
        },
      ];
    });

    expect(
      problems,
      containsAll([
        'scoreField.entryModes[0].values[0].color: "red" must look like #3A7BD5',
        'scoreField.entryModes[0].values[1].value: duplicate tile "1"',
        'scoreField.entryModes[0].values[2].size: unknown key',
        'scoreField.entryModes[1].type: unsupported value "slider"; expected one of: valuePicker',
        'scoreField.entryModes[1].id: duplicate entry mode id "cards"',
        'scoreField.entryModes[1].values: needs at least one value',
        'scoreField.entryModes[2].values: has 25 tiles; the most is 24',
      ]),
    );
  });

  test('entry modes need tap to edit', () {
    final problems = problemsFor((template) {
      final scoreField = child(template, 'scoreField');
      child(scoreField, 'entry')['tapToEdit'] = false;
      scoreField['entryModes'] = [
        {
          'type': 'valuePicker',
          'id': 'cards',
          'label': 'Cards',
          'values': [
            {'value': 1},
          ],
        },
      ];
    });

    expect(
      problems,
      contains(
        'scoreField.entryModes: need entry.tapToEdit to be true, or the entry sheet never opens',
      ),
    );
  });

  test('grouped value pickers and their totals are checked', () {
    Map<String, Object?> picker(Map<String, Object?> extra) => {
          'type': 'valuePicker',
          'id': 'cards',
          'label': 'Cards',
          ...extra,
        };

    final problems = problemsFor((template) {
      child(template, 'scoreField')['entryModes'] = [
        picker({
          'groups': [
            {
              'id': 'numbers',
              'values': [
                {'value': 2},
              ],
            },
            {
              'id': 'modifiers',
              'values': [
                {'value': 2, 'text': '+2'},
                {'value': 4, 'text': '+4'},
                {'value': 6, 'text': '+4'},
                {'value': 8, 'text': 'plus eight'},
              ],
            },
          ],
          'total': '{numbers} * 2 + {bonus} + countIn({modifiers})',
        }),
        picker({
          'values': [
            {'value': 1},
          ],
          'total': '{numbers}',
        }),
        picker({
          'values': [
            {'value': 1},
          ],
          'groups': const [],
        }),
      ];
    });

    expect(
      problems,
      containsAll([
        'scoreField.entryModes[0].groups[1].values[2].text: duplicate tile "+4"',
        'scoreField.entryModes[0].groups[1].values[3].text: must be at most 6 characters',
        'scoreField.entryModes[0].total: unknown name "bonus"; expected one of: numbers, modifiers at position 17',
        'scoreField.entryModes[0].total: countIn needs a group name without braces, for example countIn(numbers) at position 35',
        'scoreField.entryModes[1].total: needs "groups"; without groups the tiles are added up',
        'scoreField.entryModes[2].groups: use either "values" or "groups", not both',
      ]),
    );
    // The number 2 and the "+2" modifier show differently, so both are fine.
    expect(problems.where((p) => p.contains('"2"')), isEmpty);
  });

  test('row labels are checked', () {
    final problems = problemsFor((template) {
      child(template, 'scoreField')['entryModes'] = [
        {
          'type': 'valuePicker',
          'id': 'cards',
          'label': 'Cards',
          'groups': [
            {
              'id': 'bust',
              'values': [
                {'value': 1, 'text': 'Bust'},
              ],
            },
          ],
          'rowLabels': [
            {'when': '{bust} > 0', 'text': 'Bust', 'color': '#C62828'},
            {'when': '{busted} > 0', 'text': 'Busted out', 'color': 'red'},
            {'text': 'Odd', 'size': 2},
          ],
        },
        {
          'type': 'valuePicker',
          'id': 'plain',
          'label': 'Plain',
          'values': [
            {'value': 1},
          ],
          'rowLabels': [
            {'when': '1', 'text': 'Hi'},
          ],
        },
      ];
    });

    expect(
      problems,
      containsAll([
        'scoreField.entryModes[0].rowLabels[1].text: must be at most 8 characters',
        'scoreField.entryModes[0].rowLabels[1].color: "red" must look like #3A7BD5',
        'scoreField.entryModes[0].rowLabels[1].when: unknown name "busted"; expected one of: bust at position 1',
        'scoreField.entryModes[0].rowLabels[2].size: unknown key',
        'scoreField.entryModes[0].rowLabels[2].when: is required',
        'scoreField.entryModes[1].rowLabels: needs "groups" so a label can say which tiles it is about',
      ]),
    );
    expect(problems.where((p) => p.contains('rowLabels[0]')), isEmpty);
  });
}
