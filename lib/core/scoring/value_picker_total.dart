import 'package:scoard_game/application/models/scoring/score_row_label.dart';
import 'package:scoard_game/application/models/scoring/value_picker_definition.dart';
import 'package:scoard_game/core/formulas/formula_evaluator.dart';
import 'package:scoard_game/core/formulas/formula_parser.dart';

final _parsedTotals = Expando<Formula>('ValuePickerTotal');

/// The score for the tiles picked in [picker], given as indexes into its
/// options in the order they were tapped.
///
/// Without a total formula this is the sum of the picked values. With one,
/// `{group}` is the sum of that group's picked values.
int valuePickerTotal(ValuePickerDefinition picker, List<int> pickedIndexes) {
  final picked = [for (final index in pickedIndexes) picker.options[index]];
  final totalSource = picker.total;
  if (totalSource == null) {
    return picked.fold(0, (sum, option) => sum + option.value);
  }

  final formula = _parsedTotals[picker] ??= Formula.parse(totalSource);
  return evaluateFormula(formula, _PickerScope(picker, picked));
}

class _PickerScope extends FormulaScope {
  _PickerScope(ValuePickerDefinition picker, List<ValuePickerOption> picked) {
    for (final option in picker.options) {
      final groupId = option.groupId;
      if (groupId != null) {
        _picked.putIfAbsent(groupId, () => []);
      }
    }
    for (final option in picked) {
      _picked.putIfAbsent(option.groupId ?? '', () => []).add(option);
    }
  }

  final _picked = <String, List<ValuePickerOption>>{};

  @override
  int valueOf(String name) =>
      (_picked[name] ?? const []).fold(0, (sum, option) => sum + option.value);

  @override
  int countIn(String groupId) => (_picked[groupId] ?? const []).length;

  @override
  int distinctIn(String groupId) =>
      (_picked[groupId] ?? const []).map((option) => option.displayText).toSet().length;
}

final _parsedConditions = Expando<Formula>('ValuePickerRowLabelWhen');

/// The label to show on the player's row for these picked tiles: the first
/// of the picker's row labels whose condition is true, or null.
ScoreRowLabel? valuePickerRowLabel(
  ValuePickerDefinition picker,
  List<int> pickedIndexes,
) {
  if (picker.rowLabels.isEmpty || pickedIndexes.isEmpty) {
    return null;
  }

  final picked = [for (final index in pickedIndexes) picker.options[index]];
  final scope = _PickerScope(picker, picked);
  for (final rowLabel in picker.rowLabels) {
    final condition =
        _parsedConditions[rowLabel] ??= Formula.parse(rowLabel.when);
    if (evaluateFormula(condition, scope) != 0) {
      return ScoreRowLabel(text: rowLabel.text, color: rowLabel.color);
    }
  }
  return null;
}
