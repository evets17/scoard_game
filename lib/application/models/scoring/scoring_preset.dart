import 'package:scoard_game/application/models/scoring/calculated_field_definition.dart';
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
    this.isGeneral = false,
    required this.scoringModel,
    required this.minimumPlayers,
    required this.winnerRule,
    required this.scoreFields,
    this.version = '1.0.0',
    this.maximumPlayers,
    this.source,
    this.promptDefinitions = const [],
    this.calculatedFields = const [],
    this.scoreFieldId,
  });

  final String id;
  final String displayName;

  /// Short line shown under the name in Score a Game, for example to tell
  /// apart two templates for the same game.
  final String? subtitle;

  /// A general scoring style rather than a specific game. Listed first in
  /// Score a Game.
  final bool isGeneral;

  /// Longer explanation shown on the game page.
  final String description;
  final ScoringModel scoringModel;
  final int minimumPlayers;

  /// Informational only; larger games are not blocked.
  final int? maximumPlayers;
  final WinnerRule winnerRule;

  /// The entered fields.
  final List<ScoreFieldDefinition> scoreFields;

  /// Fields worked out from formulas.
  final List<CalculatedFieldDefinition> calculatedFields;

  /// The field that is each player's score. Defaults to the entered field.
  final String? scoreFieldId;
  final List<PresetPromptDefinition> promptDefinitions;
  final String version;

  /// Where the scoring rules came from.
  final String? source;

  /// The id of the field that is each player's score.
  String get scoreId => scoreFieldId ?? scoreFields.first.id;
}
