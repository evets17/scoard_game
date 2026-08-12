import 'package:scoard_game/application/models/scoring/score_field_definition.dart';
import 'package:scoard_game/application/models/scoring/score_input_kind.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/application/models/scoring/winner_rule.dart';

const finalScoreFieldId = 'final-score';

const quickFinalScoreBasicPreset = ScoringPreset(
  id: 'quick-final-score-basic',
  displayName: 'Quick Score',
  chooserDescription:
      'Use this when each player only needs one final score entered.',
  minimumPlayers: 2,
  winnerRule: WinnerRule.highestScoreWins,
  scoreFields: [
    ScoreFieldDefinition(
      id: finalScoreFieldId,
      label: 'Score',
      inputKind: ScoreInputKind.integer,
      isEntered: true,
      contributesToFinalResult: true,
      initialIntegerValue: 0,
      minimumDisplayDigits: 3,
      enableQuickAdjust: true,
      enableTapToEdit: true,
      allowReplace: true,
      allowAdjust: true,
    ),
  ],
);