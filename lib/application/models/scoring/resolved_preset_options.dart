import 'package:scoard_game/application/models/scoring/preset_prompt_answer.dart';
import 'package:scoard_game/application/models/scoring/winner_rule.dart';

class ResolvedPresetOptions {
  const ResolvedPresetOptions({
    required this.winnerRule,
    required this.promptAnswers,
  });

  final WinnerRule winnerRule;
  final List<PresetPromptAnswer> promptAnswers;
}