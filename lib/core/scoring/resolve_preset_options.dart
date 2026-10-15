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
  var gameName = preset.displayName;
  final formulaValues = <String, int>{};

  for (final definition in preset.promptDefinitions) {
    final matchingAnswer = promptAnswers.where((answer) => answer.id == definition.id).firstOrNull;
    switch (definition.kind) {
      case PresetPromptKind.boolean:
        formulaValues[definition.id] =
            (matchingAnswer?.booleanValue ?? definition.defaultBooleanValue ?? false) ? 1 : 0;
      case PresetPromptKind.integer:
        formulaValues[definition.id] =
            matchingAnswer?.integerValue ?? definition.defaultIntegerValue ?? 0;
      case PresetPromptKind.text:
        // Formulas read only numbers and switches.
        break;
    }

    switch (definition.behavior) {
      case PresetPromptBehavior.winnerRuleLowScoreToggle:
        if (matchingAnswer?.booleanValue == true) {
          winnerRule = WinnerRule.lowestScoreWins;
        }
      case PresetPromptBehavior.gameName:
        // A blank answer keeps the template's default, then its name.
        final name = [matchingAnswer?.textValue, definition.defaultTextValue]
            .map((value) => value?.trim() ?? '')
            .where((value) => value.isNotEmpty)
            .firstOrNull;
        if (name != null) {
          gameName = name;
        }
      case null:
        break;
    }
  }

  return ResolvedPresetOptions(
    winnerRule: winnerRule,
    promptAnswers: promptAnswers,
    formulaValues: formulaValues,
    gameName: gameName,
  );
}
