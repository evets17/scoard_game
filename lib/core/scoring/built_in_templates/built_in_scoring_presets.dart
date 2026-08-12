import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/core/scoring/built_in_templates/quick_final_score_basic_preset.dart';
import 'package:scoard_game/core/scoring/built_in_templates/round_score_basic_preset.dart';

const builtInScoreGamePresets = <ScoringPreset>[
  quickFinalScoreBasicPreset,
  roundScoreBasicPreset,
];

ScoringPreset getBuiltInScoringPresetById(String presetId) {
  return builtInScoreGamePresets.firstWhere(
    (preset) => preset.id == presetId,
  );
}