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
import 'package:scoard_game/application/models/sessions/quick_score_participant_values.dart';
import 'package:scoard_game/application/models/sessions/round_score_round_values.dart';
import 'package:scoard_game/core/scoring/calculate_quick_score_result.dart';
import 'package:scoard_game/core/scoring/calculate_round_score_result.dart';
import 'package:scoard_game/core/scoring/resolve_preset_options.dart';
import 'package:scoard_game/core/templates/template_catalog.dart';

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
      .where((file) => file.path.endsWith('.json'))
      .toList()
    ..sort((left, right) => left.path.compareTo(right.path));
}

String _relative(File file) => file.path.replaceAll(r'\', '/');

class _ScenarioFile {
  _ScenarioFile(this.path, this.template, this.scenarios);

  final String path;
  final ScoringPreset template;
  final List<_Scenario> scenarios;

  static _ScenarioFile parse(
    String path,
    Object? json,
    ScoringPreset template,
  ) {
    final reader = _Reader(path, json);
    reader.onlyKeys(const {'templateId', 'scenarios'});
    final templateId = reader.string('templateId');
    if (templateId != template.id) {
      reader.fail('templateId', '"$templateId" should be "${template.id}"');
    }

    final rawScenarios = reader.list('scenarios');
    if (rawScenarios.isEmpty) {
      reader.fail('scenarios', 'needs at least one scenario');
    }

    return _ScenarioFile(path, template, [
      for (var index = 0; index < rawScenarios.length; index++)
        _Scenario.parse(
          _Reader('$path: scenarios[$index]', rawScenarios[index]),
          template,
        ),
    ]);
  }

  void checkCoverage() {
    final hasTie = scenarios.any((scenario) => scenario.expectsTieForFirst);
    if (!hasTie) {
      fail('$path: add a scenario whose expected winners include a tie.');
    }

    for (final prompt in template.promptDefinitions) {
      if (prompt.behavior == null) {
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
  });

  final String name;
  final List<String> players;
  final Map<String, Object> promptValues;
  final Map<String, int>? scores;
  final List<Map<String, int>>? rounds;
  final Map<String, int>? expectedTotals;
  final Set<String>? expectedWinners;
  final Map<String, int>? expectedPlacements;

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

    Map<String, int>? scores;
    List<Map<String, int>>? rounds;
    switch (template.scoringModel) {
      case ScoringModel.finalScore:
        if (reader.has('rounds')) {
          reader.fail('rounds', 'finalScore templates use "scores"');
        }
        scores = scoresByPlayer(reader.object('scores'));
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
            scoresByPlayer(reader.child('rounds[$index]', rawRounds[index])),
        ];
    }

    final expected = reader.object('expected');
    expected.onlyKeys(const {'totals', 'winners', 'placements'});
    if (!expected.has('totals') &&
        !expected.has('winners') &&
        !expected.has('placements')) {
      expected.fail('', 'needs totals, winners, or placements');
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
    final winnerRule = resolvePresetOptions(
      preset: template,
      promptAnswers: answers,
    ).winnerRule;
    final fieldId = template.scoreFields.single.id;
    final completedAt = DateTime(2026);

    QuickScoreParticipantValues valuesFor(String player, int score) {
      return QuickScoreParticipantValues(
        playerId: player,
        displayName: player,
        enteredValues: {fieldId: score},
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
