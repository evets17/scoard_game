import 'package:scoard_game/ui/score_input/score_value_edit_action.dart';

class ScoreValueEditRequest {
  const ScoreValueEditRequest({
    required this.action,
    required this.value,
  });

  final ScoreValueEditAction action;
  final int value;
}