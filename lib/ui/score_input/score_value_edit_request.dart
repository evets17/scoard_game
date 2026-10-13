import 'package:scoard_game/application/models/scoring/value_picker_pick.dart';
import 'package:scoard_game/ui/score_input/score_value_edit_action.dart';

class ScoreValueEditRequest {
  const ScoreValueEditRequest({
    required this.action,
    required this.value,
    this.entryPick,
  });

  final ScoreValueEditAction action;
  final int value;

  /// The value picker tiles behind [value], when it came from a template's
  /// value picker; null for every other way of entering a score.
  final ValuePickerPick? entryPick;
}
