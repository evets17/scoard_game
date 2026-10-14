import 'package:scoard_game/application/models/scoring/preset_prompt_answer.dart';
import 'package:scoard_game/application/models/scoring/winner_rule.dart';

class ResolvedPresetOptions {
  const ResolvedPresetOptions({
    required this.winnerRule,
    required this.promptAnswers,
    this.formulaValues = const {},
  });

  final WinnerRule winnerRule;
  final List<PresetPromptAnswer> promptAnswers;

  /// Every prompt's answer, or its default, as formulas read it: by prompt
  /// id, with true as 1 and false as 0.
  final Map<String, int> formulaValues;
}
