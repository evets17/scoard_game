// Validates every bundled scoring template and runs its scoring scenarios.
//
// Run with `flutter test test/templates`. See _specs/template_schema_v1.md.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/application/models/scoring/card_text.dart';
import 'package:scoard_game/application/models/scoring/card_text_definition.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_answer.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_definition.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_kind.dart';
import 'package:scoard_game/application/models/scoring/scoring_model.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/application/models/scoring/value_picker_definition.dart';
import 'package:scoard_game/application/models/scoring/value_picker_pick.dart';
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
      }
    }

    // Card text is covered when some scenario expects text it could give.
    final kinds = <(String, List<CardTextDefinition>, List<String>)>[
      (
        'roundScoreLabels',
        template.scoreLabels,
        [for (final s in scenarios) ...s.expectedTexts(s.expectedRoundScoreLabels)],
      ),
      (
        'roundScoreSubLabels',
        template.scoreSubLabels,
        [for (final s in scenarios) ...s.expectedTexts(s.expectedRoundScoreSubLabels)],
      ),
      (
        'roundPlayerBadges',
        template.playerBadges,
        [
          for (final s in scenarios)
            for (final round in s.expectedRoundPlayerBadges ?? const [])
              for (final badges in round.values) ...badges,
        ],
      ),
    ];
    for (final (key, definitions, expectedTexts) in kinds) {
      for (final definition in definitions) {
        final pattern = RegExp(
          '^${definition.text.split(RegExp(r'\{[^{}]*\}')).map(RegExp.escape).join(r'-?\d+')}\$',
        );
        if (!expectedTexts.any(pattern.hasMatch)) {
          fail(
            '$path: add a scenario whose "$key" expects '
            '"${definition.text}".',
          );
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

/// Checks a value picker's total formula: tap these tiles, expect this
/// score. What the tiles show on the player card is checked in scenarios,
/// with `tiles` entries.
class _PickerTotalCheck {
  _PickerTotalCheck(this.name, this.picker, this.tappedIndexes, this.expected);

  final String name;
  final ValuePickerDefinition picker;
  final List<int> tappedIndexes;
  final int expected;

  static _PickerTotalCheck parse(_Reader reader, ScoringPreset template) {
    reader.onlyKeys(const {'name', 'picker', 'taps', 'expected'});
    final name = reader.string('name');
    final pickerId = reader.string('picker');
    final picker = template.scoreFields
        .expand((field) => field.valuePickers)
        .where((picker) => picker.id == pickerId)
        .firstOrNull;
    if (picker == null) {
      reader.fail('picker', '"$pickerId" is not a value picker in this template');
    }

    return _PickerTotalCheck(
      name,
      picker,
      _tappedIndexesFor(reader, 'taps', picker),
      reader.integer('expected'),
    );
  }

  void run() {
    expect(valuePickerTotal(picker, tappedIndexes), expected, reason: 'total');
  }
}

/// The tiles listed under [key], named by what they show, for example "8",
/// "+4", or "×2", as indexes into [picker]'s options.
List<int> _tappedIndexesFor(
  _Reader reader,
  String key,
  ValuePickerDefinition picker,
) {
  return reader.list(key).map((tap) {
    final index = picker.options.indexWhere(
      (option) => option.displayText == tap,
    );
    if (index < 0) {
      reader.fail(
        key,
        '"$tap" is not a tile; tiles are: '
            '${picker.options.map((option) => option.displayText).join(', ')}',
      );
    }
    return index;
  }).toList();
}

/// One player's entry in a scenario: the entered values (score field and
/// markers), and the tiles tapped, if any.
class _Entry {
  const _Entry(this.values, [this.pick]);

  final Map<String, int> values;
  final ValuePickerPick? pick;
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
    required this.expectedRoundScoreLabels,
    required this.expectedRoundScoreSubLabels,
    required this.expectedRoundPlayerBadges,
  });

  final String name;

  /// In play order.
  final List<String> players;
  final Map<String, Object> promptValues;

  /// Entries by player: the score field, any markers, and any tiles.
  final Map<String, _Entry>? scores;
  final List<Map<String, _Entry>>? rounds;
  final Map<String, int>? expectedTotals;
  final Set<String>? expectedWinners;
  final Map<String, int>? expectedPlacements;

  /// Each round's score per player, for rounds templates.
  final List<Map<String, int>>? expectedRoundScores;

  /// Each round's score labels and score sub labels by player. Players left
  /// out have none.
  final List<Map<String, String>>? expectedRoundScoreLabels;
  final List<Map<String, String>>? expectedRoundScoreSubLabels;

  /// Each round's player badges by player, in template order. Players left
  /// out have none.
  final List<Map<String, List<String>>>? expectedRoundPlayerBadges;

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

    // A player's entry is a number for the score field, or an object that
    // also sets markers, for example { "round-score": 10, "first-out": 1 },
    // or taps tiles, for example { "tiles": ["9", "Bust"] }. With tiles and
    // no score, the score is the picker's total.
    final scoreField = template.scoreFields.single;
    final scoreFieldId = scoreField.id;
    final markerIds = {for (final marker in template.markerFields) marker.id};
    _Entry parseEntryObject(_Reader entryReader) {
      entryReader.onlyKeys({scoreFieldId, ...markerIds, 'tiles', 'picker'});
      ValuePickerPick? pick;
      int? tilesTotal;
      if (entryReader.has('tiles')) {
        final pickerId = entryReader.has('picker')
            ? entryReader.string('picker')
            : scoreField.valuePickers.length == 1
                ? scoreField.valuePickers.single.id
                : entryReader.fail('picker', 'is required with several pickers');
        final picker = scoreField.valuePickers
            .where((picker) => picker.id == pickerId)
            .firstOrNull;
        if (picker == null) {
          entryReader.fail('picker', '"$pickerId" is not a value picker');
        }
        final tapped = _tappedIndexesFor(entryReader, 'tiles', picker);
        pick = valuePickerPickOf(picker, tapped);
        tilesTotal = valuePickerTotal(picker, tapped);
      }
      return _Entry(
        {
          scoreFieldId: entryReader.has(scoreFieldId) || tilesTotal == null
              ? entryReader.integer(scoreFieldId)
              : tilesTotal,
          for (final markerId in markerIds)
            if (entryReader.has(markerId))
              markerId: entryReader.integer(markerId),
        },
        pick,
      );
    }

    Map<String, _Entry> enteredByPlayer(_Reader entriesReader) {
      entriesReader.onlyKeys(players.toSet());
      return {
        for (final player in players)
          player: switch (entriesReader.map[player]) {
            final int score => _Entry({scoreFieldId: score}),
            final Map<String, Object?> entry =>
              parseEntryObject(entriesReader.child(player, entry)),
            _ => entriesReader.fail(
                player,
                'must be a whole number, or an object with "$scoreFieldId" '
                'or "tiles"',
              ),
          },
      };
    }

    Map<String, _Entry>? scores;
    List<Map<String, _Entry>>? rounds;
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

    const roundKeys = {
      'roundScores',
      'roundScoreLabels',
      'roundScoreSubLabels',
      'roundPlayerBadges',
    };
    final expected = reader.object('expected');
    expected.onlyKeys({'totals', 'winners', 'placements', ...roundKeys});
    if (!expected.map.keys.any(
      {'totals', 'winners', 'placements', ...roundKeys}.contains,
    )) {
      expected.fail(
        '',
        'needs totals, winners, placements, or one of ${roundKeys.join(', ')}',
      );
    }

    /// One value per player per round under [key], for rounds templates.
    /// Players left out of a round are left out of its map.
    List<Map<String, T>>? perRound<T>(
      String key,
      T Function(_Reader values, String player) read,
    ) {
      if (!expected.has(key)) {
        return null;
      }
      if (rounds == null) {
        expected.fail(key, 'only applies to rounds templates');
      }
      final rawRounds = expected.list(key);
      if (rawRounds.length != rounds.length) {
        expected.fail(
          key,
          'has ${rawRounds.length} rounds but the scenario has '
              '${rounds.length}',
        );
      }
      return [
        for (var index = 0; index < rawRounds.length; index++)
          () {
            final values = expected.child('$key[$index]', rawRounds[index]);
            values.onlyKeys(players.toSet());
            return {
              for (final player in values.map.keys)
                player: read(values, player),
            };
          }(),
      ];
    }

    List<Map<String, String>>? perRoundTexts(String key) =>
        perRound(key, (values, player) => values.string(player));

    final roundScores = perRound(
      'roundScores',
      (values, player) => values.integer(player),
    );
    if (roundScores != null) {
      for (final (index, round) in roundScores.indexed) {
        if (round.length != players.length) {
          expected.fail('roundScores[$index]', 'needs every player');
        }
      }
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
      expectedRoundScoreLabels: perRoundTexts('roundScoreLabels'),
      expectedRoundScoreSubLabels: perRoundTexts('roundScoreSubLabels'),
      expectedRoundPlayerBadges: perRound('roundPlayerBadges', (values, player) {
        return [
          for (final badge in values.list(player))
            if (badge is String)
              badge
            else
              values.fail(player, 'must be a list of badge texts'),
        ];
      }),
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

    QuickScoreParticipantValues valuesFor(String player, _Entry entry) {
      return QuickScoreParticipantValues(
        playerId: player,
        displayName: player,
        enteredValues: entry.values,
        entryPicks: {
          template.scoreFields.single.id: ?entry.pick,
        },
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
    final cardChecks = [
      (expectedRoundScoreLabels, 'score labels',
          (PlayerCardTexts texts) => texts.scoreLabel?.text),
      (expectedRoundScoreSubLabels, 'score sub labels',
          (PlayerCardTexts texts) => texts.scoreSubLabel?.text),
    ];
    final expectedBadges = expectedRoundPlayerBadges;
    if (cardChecks.any((check) => check.$1 != null) || expectedBadges != null) {
      final engine = ScoreEngine.of(template);
      for (var index = 0; index < rounds!.length; index++) {
        final texts = engine.cardTexts(
          [
            for (final player in players)
              valuesFor(player, rounds![index][player]!),
          ],
          roundNumber: index + 1,
          options: options,
        );
        for (final (expected, kind, textOf) in cardChecks) {
          if (expected == null) {
            continue;
          }
          expect(
            {
              for (final entry in texts.entries)
                if (textOf(entry.value) case final String text) entry.key: text,
            },
            expected[index],
            reason: 'round ${index + 1} $kind',
          );
        }
        if (expectedBadges != null) {
          expect(
            {
              for (final entry in texts.entries)
                if (entry.value.playerBadges.isNotEmpty)
                  entry.key: [
                    for (final badge in entry.value.playerBadges) badge.text,
                  ],
            },
            expectedBadges[index],
            reason: 'round ${index + 1} player badges',
          );
        }
      }
    }
  }

  /// Every text expected in [rounds] of card text.
  Iterable<String> expectedTexts(List<Map<String, String>>? rounds) =>
      (rounds ?? const []).expand((round) => round.values);
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
