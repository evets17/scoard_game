import 'package:scoard_game/application/models/scoring/score_field_definition.dart';
import 'package:scoard_game/application/models/scoring/score_input_kind.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/application/models/scoring/winner_rule.dart';
import 'package:scoard_game/core/scoring/built_in_templates/shared_prompt_definitions.dart';

const roundScoreFieldId = 'round-score';

const roundScoreBasicPreset = ScoringPreset(
  id: 'round-score-basic',
  displayName: 'Round Score',
  chooserDescription:
      'Use this when each round has one score per player and totals add up over time.',
  minimumPlayers: 2,
  winnerRule: WinnerRule.highestScoreWins,
  promptDefinitions: [
    lowScoreWinsPromptDefinition,
  ],
  scoreFields: [
    ScoreFieldDefinition(
      id: roundScoreFieldId,
      label: 'Round Score',
      inputKind: ScoreInputKind.integer,
      isEntered: true,
      contributesToFinalResult: true,
      initialIntegerValue: 0,
      minimumDisplayDigits: 2,
      enableQuickAdjust: true,
      enableTapToEdit: true,
      allowReplace: true,
      allowAdjust: true,
    ),
  ],
);