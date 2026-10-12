import 'package:scoard_game/application/models/scoring/preset_prompt_definition.dart';
import 'package:scoard_game/application/models/scoring/score_field_definition.dart';
import 'package:scoard_game/application/models/scoring/scoring_model.dart';
import 'package:scoard_game/application/models/scoring/winner_rule.dart';

/// A scoring template, as read from a template file.
class ScoringPreset {
  const ScoringPreset({
    required this.id,
    required this.displayName,
    required this.chooserDescription,
    required this.scoringModel,
    required this.minimumPlayers,
    required this.winnerRule,
    required this.scoreFields,
    this.version = '1.0.0',
    this.maximumPlayers,
    this.source,
    this.promptDefinitions = const [],
  });

  final String id;
  final String displayName;
  final String chooserDescription;
  final ScoringModel scoringModel;
  final int minimumPlayers;

  /// Informational only; larger games are not blocked.
  final int? maximumPlayers;
  final WinnerRule winnerRule;
  final List<ScoreFieldDefinition> scoreFields;
  final List<PresetPromptDefinition> promptDefinitions;
  final String version;

  /// Where the scoring rules came from.
  final String? source;
}
