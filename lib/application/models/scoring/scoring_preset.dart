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
  });

  final String id;
  final String displayName;
  final String chooserDescription;
  final int minimumPlayers;
  final WinnerRule winnerRule;
  final List<ScoreFieldDefinition> scoreFields;
}