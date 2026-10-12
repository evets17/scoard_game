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
      template['schemaVersion'] = 2;
      template['version'] = 'one';
      template['scoringModel'] = 'categories';
      child(template, 'players')['minimum'] = 1.5;
      child(child(template, 'scoreField'), 'entry')['adjust'] = 'yes';
    });

    expect(
      problems,
      containsAll([
        'schemaVersion: unsupported version 2; expected 1',
        'version: "one" must look like 1.0.0',
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
}
