import 'package:scoard_game/application/models/scoring/preset_prompt_definition.dart';
import 'package:scoard_game/application/models/scoring/score_field_definition.dart';
import 'package:scoard_game/application/models/scoring/scoring_model.dart';
import 'package:scoard_game/application/models/scoring/winner_rule.dart';

/// A scoring template, as read from a template file.
class ScoringPreset {
  const ScoringPreset({
    required this.id,
    required this.displayName,
    required this.description,
    this.subtitle,
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
  /// Short line shown under the name in Score a Game, for example to tell
  /// apart two templates for the same game.
  final String? subtitle;

  /// Longer explanation shown on the game page.
  final String description;
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
