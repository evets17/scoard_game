import 'package:scoard_game/application/models/scoring/preset_prompt_answer.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_behavior.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_kind.dart';
import 'package:scoard_game/application/models/scoring/resolved_preset_options.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/application/models/scoring/winner_rule.dart';

ResolvedPresetOptions resolvePresetOptions({
  required ScoringPreset preset,
  List<PresetPromptAnswer> promptAnswers = const [],
}) {
  var winnerRule = preset.winnerRule;
  final formulaValues = <String, int>{};

  for (final definition in preset.promptDefinitions) {
    final matchingAnswer = promptAnswers.where((answer) => answer.id == definition.id).firstOrNull;
    formulaValues[definition.id] = switch (definition.kind) {
      PresetPromptKind.boolean =>
        (matchingAnswer?.booleanValue ?? definition.defaultBooleanValue ?? false) ? 1 : 0,
      PresetPromptKind.integer =>
        matchingAnswer?.integerValue ?? definition.defaultIntegerValue ?? 0,
    };
    if (matchingAnswer == null) {
      continue;
    }

    switch (definition.behavior) {
      case PresetPromptBehavior.winnerRuleLowScoreToggle:
        if (matchingAnswer.booleanValue == true) {
          winnerRule = WinnerRule.lowestScoreWins;
        }
      case null:
        break;
    }
  }

  return ResolvedPresetOptions(
    winnerRule: winnerRule,
    promptAnswers: promptAnswers,
    formulaValues: formulaValues,
  );
}
