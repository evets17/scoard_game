import 'package:scoard_game/application/models/scoring/preset_prompt_answer.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_behavior.dart';
import 'package:scoard_game/application/models/scoring/resolved_preset_options.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/application/models/scoring/winner_rule.dart';

ResolvedPresetOptions resolvePresetOptions({
  required ScoringPreset preset,
  List<PresetPromptAnswer> promptAnswers = const [],
}) {
  var winnerRule = preset.winnerRule;

  for (final definition in preset.promptDefinitions) {
    final matchingAnswer = promptAnswers.where((answer) => answer.id == definition.id).firstOrNull;
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
  );
}