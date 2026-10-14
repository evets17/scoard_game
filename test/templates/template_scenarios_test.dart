// Validates every bundled scoring template and runs its scoring scenarios.
//
// Run with `flutter test test/templates`. See _specs/template_schema_v1.md.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_answer.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_definition.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_kind.dart';
import 'package:scoard_game/application/models/scoring/scoring_model.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/application/models/scoring/value_picker_definition.dart';
import 'package:scoard_game/application/models/sessions/quick_score_participant_values.dart';
import 'package:scoard_game/application/models/sessions/round_score_round_values.dart';
import 'package:scoard_game/core/scoring/calculate_quick_score_result.dart';
import 'package:scoard_game/core/scoring/calculate_round_score_result.dart';
import 'package:scoard_game/core/scoring/resolve_preset_options.dart';
import 'package:scoard_game/core/scoring/score_engine.dart';
import 'package:scoard_game/core/scoring/value_picker_total.dart';
import 'package:scoard_game/core/templates/template_catalog.dart';
import 'package:scoard_game/core/templates/template_index.dart';

const _templateDirectory = 'assets/templates';
const _scenarioDirectory = 'test/templates/scenarios';

void main() {
  final templateFiles = _jsonFilesIn(_templateDirectory);
  final scenarioFiles = _jsonFilesIn(_scenarioDirectory);
  final loadResult = loadTemplateCatalog({
    for (final file in templateFiles) _relative(file): file.readAsStringSync(),
  });

  test('every bundled template is valid', () {
    expect(templateFiles, isNotEmpty);
    if (loadResult.hasProblems) {
      fail('Template problems:\n${loadResult.describeProblems()}');
    }
  });

  test('every template has a scenario file, and every scenario file a template', () {
    final templateIds = loadResult.catalog.templates.map((t) => t.id).toSet();
    final scenarioIds = scenarioFiles.map((file) => templateIdFromPath(file.path)).toSet();

    final missingScenarios = templateIds.difference(scenarioIds);
    final orphanScenarios = scenarioIds.difference(templateIds);
    expect(
      missingScenarios,
      isEmpty,
      reason: 'Add $_scenarioDirectory/<id>.json for: '
          '${missingScenarios.join(', ')}',
    );
    expect(
      orphanScenarios,
      isEmpty,
      reason: 'No template matches these scenario files: '
          '${orphanScenarios.join(', ')}',
    );
  });

  for (final file in scenarioFiles) {
    final id = templateIdFromPath(file.path);
    final template = loadResult.catalog.maybeById(id);
    if (template == null) {
      continue;
    }

    group(template.displayName, () {
      final scenarioFile = _ScenarioFile.parse(
        _relative(file),
        jsonDecode(file.readAsStringSync()),
        template,
      );

      test('scenario file covers a tie and every prompt effect', () {
        scenarioFile.checkCoverage();
      });

      for (final check in scenarioFile.pickerTotals) {
        test('picker total: ${check.name}', check.run);
      }

      for (final scenario in scenarioFile.scenarios) {
        test(scenario.name, () => scenario.run(template));
      }
    });
  }
}

List<File> _jsonFilesIn(String directory) {
  final dir = Directory(directory);
  if (!dir.existsSync()) {
    return const [];
  }
  return dir
      .listSync()
      .whereType<File>()
      .where((file) => isTemplateFilePath(file.path))
      .toList()
    ..sort((left, right) => left.path.compareTo(right.path));
}

String _relative(File file) => file.path.replaceAll(r'\', '/');

class _ScenarioFile {
  _ScenarioFile(this.path, this.template, this.scenarios, this.pickerTotals);

  final String path;
  final ScoringPreset template;
  final List<_Scenario> scenarios;
  final List<_PickerTotalCheck> pickerTotals;

  static _ScenarioFile parse(
    String path,
    Object? json,
    ScoringPreset template,
  ) {
    final reader = _Reader(path, json);
    reader.onlyKeys(const {'templateId', 'scenarios', 'pickerTotals'});
    final templateId = reader.string('templateId');
    if (templateId != template.id) {
      reader.fail('templateId', '"$templateId" should be "${template.id}"');
    }

    final rawScenarios = reader.list('scenarios');
    if (rawScenarios.isEmpty) {
      reader.fail('scenarios', 'needs at least one scenario');
    }

    final rawPickerTotals =
        reader.has('pickerTotals') ? reader.list('pickerTotals') : const [];

    return _ScenarioFile(
      path,
      template,
      [
        for (var index = 0; index < rawScenarios.length; index++)
          _Scenario.parse(
            _Reader('$path: scenarios[$index]', rawScenarios[index]),
            template,
          ),
      ],
      [
        for (var index = 0; index < rawPickerTotals.length; index++)
          _PickerTotalCheck.parse(
            _Reader('$path: pickerTotals[$index]', rawPickerTotals[index]),
            template,
          ),
      ],
    );
  }

  void checkCoverage() {
    for (final field in template.scoreFields) {
      for (final picker in field.valuePickers) {
        final checked = pickerTotals.any((check) => check.picker == picker);
        if (picker.total != null && !checked) {
          fail(
            '$path: add a pickerTotals check for value picker "${picker.id}", '
            'which has a total formula.',
          );
        }
        for (final rowLabel in picker.rowLabels) {
          final labelChecked = pickerTotals.any(
            (check) =>
                check.picker == picker &&
                (check.expectedLabel == rowLabel.text ||
                    (check.expectedBadges?.contains(rowLabel.text) ?? false)),
          );
          if (!labelChecked) {
            fail(
              '$path: add a pickerTotals check whose "label" is '
              '"${rowLabel.text}" for value picker "${picker.id}".',
            );
          }
        }
      }
    }

    final hasTie = scenarios.any((scenario) => scenario.expectsTieForFirst);
    if (!hasTie) {
      fail('$path: add a scenario whose expected winners include a tie.');
    }

    for (final prompt in template.promptDefinitions) {
      final readByFormula = template.calculatedFields
          .any((field) => field.formula.contains('{${prompt.id}}'));
      if (prompt.behavior == null && !readByFormula) {
        continue;
      }
      final exercised = scenarios.any(
        (scenario) => scenario.setsNonDefault(prompt),
      );
      if (!exercised) {
        fail(
          '$path: add a scenario that answers prompt "${prompt.id}" '
          'with a non-default value.',
        );
      }
    }
  }
}

/// Checks a value picker's total formula: tap these tiles, expect this score
/// and, optionally, this row label.
class _PickerTotalCheck {
  _PickerTotalCheck(
    this.name,
    this.picker,
    this.tappedIndexes,
    this.expected, {
    required this.checksLabel,
    required this.expectedLabel,
    required this.expectedBadges,
  });

  final String name;
  final ValuePickerDefinition picker;
  final List<int> tappedIndexes;
  final int expected;

  /// Whether the check names a label; `"label": null` expects none.
  final bool checksLabel;
  final String? expectedLabel;

  /// Badge texts the taps should give, in order, if the check names them.
  final List<String>? expectedBadges;

  static _PickerTotalCheck parse(_Reader reader, ScoringPreset template) {
    reader.onlyKeys(
      const {'name', 'picker', 'taps', 'expected', 'label', 'badges'},
    );
    final expectedBadges = reader.has('badges')
        ? [
            for (final badge in reader.list('badges'))
              if (badge is String)
                badge
              else
                reader.fail('badges', 'must be a list of badge texts'),
          ]
        : null;
    final checksLabel = reader.has('label');
    final expectedLabel = reader.map['label'];
    if (expectedLabel != null && expectedLabel is! String) {
      reader.fail('label', 'must be the label text, or null for no label');
    }
    final name = reader.string('name');
    final pickerId = reader.string('picker');
    final picker = template.scoreFields
        .expand((field) => field.valuePickers)
        .where((picker) => picker.id == pickerId)
        .firstOrNull;
    if (picker == null) {
      reader.fail('picker', '"$pickerId" is not a value picker in this template');
    }

    // Tiles are named by what they show, for example "8", "+4", or "×2".
    final tappedIndexes = reader.list('taps').map((tap) {
      final index = picker.options.indexWhere(
        (option) => option.displayText == tap,
      );
      if (index < 0) {
        reader.fail(
          'taps',
          '"$tap" is not a tile; tiles are: '
              '${picker.options.map((option) => option.displayText).join(', ')}',
        );
      }
      return index;
    }).toList();

    return _PickerTotalCheck(
      name,
      picker,
      tappedIndexes,
      reader.integer('expected'),
      checksLabel: checksLabel,
      expectedLabel: expectedLabel as String?,
      expectedBadges: expectedBadges,
    );
  }

  void run() {
    expect(valuePickerTotal(picker, tappedIndexes), expected, reason: 'total');
    if (checksLabel) {
      expect(
        valuePickerRowLabel(picker, tappedIndexes)?.text,
        expectedLabel,
        reason: 'row label',
      );
    }
    if (expectedBadges != null) {
      expect(
        valuePickerBadges(picker, tappedIndexes).map((badge) => badge.text),
        expectedBadges,
        reason: 'badges',
      );
    }
  }
}

class _Scenario {
  _Scenario({
    required this.name,
    required this.players,
    required this.promptValues,
    required this.scores,
    required this.rounds,
    required this.expectedTotals,
    required this.expectedWinners,
    required this.expectedPlacements,
    required this.expectedRoundScores,
  });

  final String name;
  final List<String> players;
  final Map<String, Object> promptValues;
  /// Entered values by player: the score field, plus any markers.
  final Map<String, Map<String, int>>? scores;
  final List<Map<String, Map<String, int>>>? rounds;
  final Map<String, int>? expectedTotals;
  final Set<String>? expectedWinners;
  final Map<String, int>? expectedPlacements;

  /// Each round's score per player, for rounds templates.
  final List<Map<String, int>>? expectedRoundScores;

  bool get expectsTieForFirst {
    if ((expectedWinners?.length ?? 0) > 1) {
      return true;
    }
    final firsts = expectedPlacements?.values.where((place) => place == 1);
    return (firsts?.length ?? 0) > 1;
  }

  bool setsNonDefault(PresetPromptDefinition prompt) {
    final value = promptValues[prompt.id];
    if (value == null) {
      return false;
    }
    return switch (prompt.kind) {
      PresetPromptKind.boolean => value != (prompt.defaultBooleanValue ?? false),
      PresetPromptKind.integer => value != prompt.defaultIntegerValue,
    };
  }

  static _Scenario parse(_Reader reader, ScoringPreset template) {
    reader.onlyKeys(const {'name', 'players', 'prompts', 'scores', 'rounds', 'expected'});
    final name = reader.string('name');

    final players = reader.list('players').map((player) {
      if (player is! String || player.trim().isEmpty) {
        reader.fail('players', 'must be a list of names');
      }
      return player;
    }).toList();
    if (players.toSet().length != players.length) {
      reader.fail('players', 'names must be unique');
    }
    if (players.length < template.minimumPlayers) {
      reader.fail('players', 'needs at least ${template.minimumPlayers} players');
    }

    final promptValues = <String, Object>{};
    final prompts = reader.optionalObject('prompts');
    if (prompts != null) {
      for (final entry in prompts.map.entries) {
        final definition = template.promptDefinitions
            .where((prompt) => prompt.id == entry.key)
            .firstOrNull;
        if (definition == null) {
          prompts.fail(entry.key, 'is not a prompt in this template');
        }
        final valid = switch (definition.kind) {
          PresetPromptKind.boolean => entry.value is bool,
          PresetPromptKind.integer => entry.value is int,
        };
        if (!valid) {
          prompts.fail(entry.key, 'must be a ${definition.kind.name}');
        }
        promptValues[entry.key] = entry.value!;
      }
    }

    Map<String, int> scoresByPlayer(_Reader scoresReader) {
      scoresReader.onlyKeys(players.toSet());
      return {
        for (final player in players) player: scoresReader.integer(player),
      };
    }

    // A player's entry is a number for the score field, or an object that
    // also sets markers, for example { "round-score": 10, "first-out": 1 }.
    final scoreFieldId = template.scoreFields.single.id;
    final markerIds = {for (final marker in template.markerFields) marker.id};
    Map<String, Map<String, int>> enteredByPlayer(_Reader entriesReader) {
      entriesReader.onlyKeys(players.toSet());
      return {
        for (final player in players)
          player: switch (entriesReader.map[player]) {
            final int score => {scoreFieldId: score},
            final Map<String, Object?> entry => () {
                final entryReader = entriesReader.child(player, entry);
                entryReader.onlyKeys({scoreFieldId, ...markerIds});
                return {
                  scoreFieldId: entryReader.integer(scoreFieldId),
                  for (final markerId in markerIds)
                    if (entryReader.has(markerId))
                      markerId: entryReader.integer(markerId),
                };
              }(),
            _ => entriesReader.fail(
                player,
                'must be a whole number, or an object with "$scoreFieldId"',
              ),
          },
      };
    }

    Map<String, Map<String, int>>? scores;
    List<Map<String, Map<String, int>>>? rounds;
    switch (template.scoringModel) {
      case ScoringModel.finalScore:
        if (reader.has('rounds')) {
          reader.fail('rounds', 'finalScore templates use "scores"');
        }
        scores = enteredByPlayer(reader.object('scores'));
      case ScoringModel.rounds:
        if (reader.has('scores')) {
          reader.fail('scores', 'rounds templates use "rounds"');
        }
        final rawRounds = reader.list('rounds');
        if (rawRounds.isEmpty) {
          reader.fail('rounds', 'needs at least one round');
        }
        rounds = [
          for (var index = 0; index < rawRounds.length; index++)
            enteredByPlayer(reader.child('rounds[$index]', rawRounds[index])),
        ];
    }

    final expected = reader.object('expected');
    expected.onlyKeys(const {'totals', 'winners', 'placements', 'roundScores'});
    if (!expected.has('totals') &&
        !expected.has('winners') &&
        !expected.has('placements') &&
        !expected.has('roundScores')) {
      expected.fail('', 'needs totals, winners, placements, or roundScores');
    }

    List<Map<String, int>>? roundScores;
    if (expected.has('roundScores')) {
      if (rounds == null) {
        expected.fail('roundScores', 'only applies to rounds templates');
      }
      final rawRoundScores = expected.list('roundScores');
      if (rawRoundScores.length != rounds.length) {
        expected.fail(
          'roundScores',
          'has ${rawRoundScores.length} rounds but the scenario has '
              '${rounds.length}',
        );
      }
      roundScores = [
        for (var index = 0; index < rawRoundScores.length; index++)
          scoresByPlayer(
            expected.child('roundScores[$index]', rawRoundScores[index]),
          ),
      ];
    }

    Map<String, int>? perPlayer(String key) {
      final values = expected.optionalObject(key);
      if (values == null) {
        return null;
      }
      values.onlyKeys(players.toSet());
      return {
        for (final player in values.map.keys) player: values.integer(player),
      };
    }

    Set<String>? winners;
    if (expected.has('winners')) {
      winners = expected.list('winners').map((winner) {
        if (!players.contains(winner)) {
          expected.fail('winners', '"$winner" is not one of the players');
        }
        return winner! as String;
      }).toSet();
    }

    return _Scenario(
      name: name,
      players: players,
      promptValues: promptValues,
      scores: scores,
      rounds: rounds,
      expectedTotals: perPlayer('totals'),
      expectedWinners: winners,
      expectedPlacements: perPlayer('placements'),
      expectedRoundScores: roundScores,
    );
  }

  void run(ScoringPreset template) {
    final answers = [
      for (final prompt in template.promptDefinitions)
        if (prompt.kind == PresetPromptKind.boolean)
          PresetPromptAnswer.boolean(
            id: prompt.id,
            value: (promptValues[prompt.id] as bool?) ??
                prompt.defaultBooleanValue ??
                false,
          )
        else if ((promptValues[prompt.id] ?? prompt.defaultIntegerValue) != null)
          PresetPromptAnswer.integer(
            id: prompt.id,
            value: (promptValues[prompt.id] as int?) ?? prompt.defaultIntegerValue!,
          ),
    ];
    final resolved = resolvePresetOptions(
      preset: template,
      promptAnswers: answers,
    );
    final winnerRule = resolved.winnerRule;
    final options = resolved.formulaValues;
    final completedAt = DateTime(2026);

    QuickScoreParticipantValues valuesFor(
      String player,
      Map<String, int> enteredValues,
    ) {
      return QuickScoreParticipantValues(
        playerId: player,
        displayName: player,
        enteredValues: enteredValues,
      );
    }

    final Map<String, int> totals;
    final Map<String, int> placements;
    final Set<String> winners;
    switch (template.scoringModel) {
      case ScoringModel.finalScore:
        final result = calculateQuickScoreResult(
          sessionId: 'scenario',
          preset: template,
          completedAt: completedAt,
          winnerRule: winnerRule,
          options: options,
          participantValues: [
            for (final player in players) valuesFor(player, scores![player]!),
          ],
        );
        totals = {
          for (final r in result.playerResults) r.playerId: r.finalScore,
        };
        placements = {
          for (final r in result.playerResults) r.playerId: r.placement,
        };
        winners = result.winners.map((r) => r.playerId).toSet();
      case ScoringModel.rounds:
        final result = calculateRoundScoreResult(
          sessionId: 'scenario',
          preset: template,
          completedAt: completedAt,
          winnerRule: winnerRule,
          options: options,
          rounds: [
            for (var index = 0; index < rounds!.length; index++)
              RoundScoreRoundValues(
                roundNumber: index + 1,
                participantValues: [
                  for (final player in players)
                    valuesFor(player, rounds![index][player]!),
                ],
              ),
          ],
        );
        totals = {
          for (final r in result.playerResults) r.playerId: r.cumulativeScore,
        };
        placements = {
          for (final r in result.playerResults) r.playerId: r.placement,
        };
        winners = result.winners.map((r) => r.playerId).toSet();
    }

    if (expectedTotals != null) {
      expect(totals, expectedTotals, reason: 'totals');
    }
    if (expectedWinners != null) {
      expect(winners, expectedWinners, reason: 'winners');
    }
    if (expectedPlacements != null) {
      expect(placements, expectedPlacements, reason: 'placements');
    }
    final expectedRounds = expectedRoundScores;
    if (expectedRounds != null) {
      final engine = ScoreEngine.of(template);
      for (var index = 0; index < expectedRounds.length; index++) {
        final roundScores = engine.scores(
          [
            for (final player in players)
              valuesFor(player, rounds![index][player]!),
          ],
          roundNumber: index + 1,
          options: options,
        );
        expect(
          roundScores,
          expectedRounds[index],
          reason: 'round ${index + 1} scores',
        );
      }
    }
  }
}

/// Reads a scenario JSON object, failing the test with a path on bad input.
class _Reader {
  _Reader(this.path, Object? value) {
    if (value is! Map<String, Object?>) {
      throw TestFailure('$path: must be an object');
    }
    map = value;
  }

  final String path;
  late final Map<String, Object?> map;

  Never fail(String key, String message) {
    throw TestFailure(key.isEmpty ? '$path: $message' : '$path.$key: $message');
  }

  bool has(String key) => map.containsKey(key);

  void onlyKeys(Set<String> keys) {
    for (final key in map.keys) {
      if (!keys.contains(key)) {
        fail(key, 'unknown key');
      }
    }
  }

  String string(String key) {
    final value = map[key];
    if (value is! String || value.trim().isEmpty) {
      fail(key, 'must be a non-empty string');
    }
    return value;
  }

  int integer(String key) {
    final value = map[key];
    if (value is! int) {
      fail(key, 'must be a whole number');
    }
    return value;
  }

  List<Object?> list(String key) {
    final value = map[key];
    if (value is! List<Object?>) {
      fail(key, 'must be a list');
    }
    return value;
  }

  _Reader object(String key) {
    if (!has(key)) {
      fail(key, 'is required');
    }
    return child(key, map[key]);
  }

  _Reader? optionalObject(String key) => has(key) ? object(key) : null;

  _Reader child(String key, Object? value) => _Reader('$path.$key', value);
}
