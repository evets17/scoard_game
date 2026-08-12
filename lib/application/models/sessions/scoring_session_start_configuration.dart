import 'package:scoard_game/application/models/scoring/preset_prompt_answer.dart';

class ScoringSessionStartConfiguration {
  const ScoringSessionStartConfiguration({
    required this.presetId,
    this.promptAnswers = const [],
  });

  final String presetId;
  final List<PresetPromptAnswer> promptAnswers;
}