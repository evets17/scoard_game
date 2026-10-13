import 'package:scoard_game/application/models/scoring/score_row_label.dart';
import 'package:scoard_game/ui/score_input/score_value_edit_action.dart';

class ScoreValueEditRequest {
  const ScoreValueEditRequest({
    required this.action,
    required this.value,
    this.rowLabel,
  });

  final ScoreValueEditAction action;
  final int value;

  /// A label to show instead of the score, such as "Bust", when the value
  /// came from a value picker that defines one.
  final ScoreRowLabel? rowLabel;
}
