import 'package:scoard_game/application/models/scoring/preset_prompt_definition.dart';
import 'package:scoard_game/application/models/scoring/score_field_definition.dart';
import 'package:scoard_game/application/models/scoring/winner_rule.dart';

class ScoringPreset {
  const ScoringPreset({
    required this.id,
    required this.displayName,
    required this.chooserDescription,
    required this.minimumPlayers,
    required this.winnerRule,
    required this.scoreFields,
    this.promptDefinitions = const [],
  });

  final String id;
  final String displayName;
  final String chooserDescription;
  final int minimumPlayers;
  final WinnerRule winnerRule;
  final List<ScoreFieldDefinition> scoreFields;
  final List<PresetPromptDefinition> promptDefinitions;
}