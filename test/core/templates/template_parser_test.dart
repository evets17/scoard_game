import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_behavior.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_kind.dart';
import 'package:scoard_game/application/models/scoring/scoring_model.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/application/models/scoring/winner_rule.dart';
import 'package:scoard_game/core/templates/template_catalog.dart';

void main() {
  ScoringPreset loadBundled(String id) {
    final path = 'assets/templates/$id.json';
    final result = loadTemplateCatalog({path: File(path).readAsStringSync()});
    expect(result.describeProblems(), isEmpty);
    return result.catalog.byId(id);
  }

  // The values the original Dart presets had, so converting them to JSON
  // changes nothing for saved or in-progress games.
  void expectBuiltInShape(
    ScoringPreset preset, {
    required String name,
    required ScoringModel scoringModel,
    required String lineId,
    required String lineLabel,
    required int digits,
  }) {
    expect(preset.displayName, name);
    expect(preset.scoringModel, scoringModel);
    expect(preset.minimumPlayers, 2);
    expect(preset.winnerRule, WinnerRule.highestScoreWins);

    final prompt = preset.promptDefinitions.single;
    expect(prompt.id, 'low-score-wins');
    expect(prompt.kind, PresetPromptKind.boolean);
    expect(prompt.label, 'Low Score Wins');
    expect(
      prompt.promptText,
      'Turn this on for games where the lowest total is the winner.',
    );
    expect(prompt.behavior, PresetPromptBehavior.winnerRuleLowScoreToggle);
    expect(prompt.defaultBooleanValue, isFalse);

    final line = preset.enteredLines.single;
    expect(line.id, lineId);
    expect(line.label, lineLabel);
    expect(line.isEntered, isTrue);
    expect(line.contributesToFinalResult, isTrue);
    expect(line.initialIntegerValue, 0);
    expect(line.minimumDisplayDigits, digits);
    expect(line.enableQuickAdjust, isTrue);
    expect(line.enableTapToEdit, isTrue);
    expect(line.allowReplace, isTrue);
    expect(line.allowAdjust, isTrue);
  }

  test('Quick Score parses to the same preset the app always had', () {
    final preset = loadBundled('quick-final-score-basic');

    expectBuiltInShape(
      preset,
      name: 'Quick Score',
      scoringModel: ScoringModel.finalScore,
      lineId: 'final-score',
      lineLabel: 'Score',
      digits: 3,
    );
    expect(
      preset.description,
      'Use this when each player only needs one final score entered.',
    );
    expect(preset.subtitle, 'One final score per player');
  });

  test('Round Score parses to the same preset the app always had', () {
    final preset = loadBundled('round-score-basic');

    expectBuiltInShape(
      preset,
      name: 'Round Score',
      scoringModel: ScoringModel.rounds,
      lineId: 'round-score',
      lineLabel: 'Round Score',
      digits: 2,
    );
    expect(
      preset.description,
      'Use this when each round has one score per player and totals add up over time.',
    );
    expect(preset.subtitle, 'Scores add up each round');
  });

  test('optional entry settings default like the original score line', () {
    final result = loadTemplateCatalog({
      'skyjo.json': '{"schemaVersion": 1, "id": "skyjo", "version": "1.0.0", '
          '"name": "Skyjo", "description": "x", "players": {"minimum": 2}, '
          '"scoringModel": "rounds", "winner": "lowestScore", '
          '"lines": [{"id": "round-score", "label": "Round Score"}]}',
    });
    final preset = result.catalog.byId('skyjo');
    final line = preset.enteredLines.single;

    expect(line.minimumDisplayDigits, 1);
    expect(line.enableTapToEdit, isFalse);
    expect(line.enableQuickAdjust, isFalse);
    expect(line.allowReplace, isTrue);
    expect(line.allowAdjust, isFalse);
    expect(line.quickPickRange, isNull);
    expect(preset.winnerRule, WinnerRule.lowestScoreWins);
  });

  test('Skyjo offers a Cards picker from -2 to 12', () {
    final picker = loadBundled('skyjo').enteredLines.single.valuePickers.single;

    expect(picker.id, 'cards');
    expect(picker.label, 'Cards');
    expect(
      picker.options.map((option) => option.value),
      [for (var value = -2; value <= 12; value++) value],
    );
    expect(picker.options.first.color, '#3949AB');
  });
}
