import 'package:scoard_game/application/models/scoring/preset_prompt_behavior.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_definition.dart';

const lowScoreWinsPromptDefinition = PresetPromptDefinition.boolean(
  id: 'low-score-wins',
  label: 'Low Score Wins',
  promptText: 'Turn this on for games where the lowest total is the winner.',
  behavior: PresetPromptBehavior.winnerRuleLowScoreToggle,
  defaultBooleanValue: false,
);