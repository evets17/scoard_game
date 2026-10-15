import 'package:scoard_game/application/models/scoring/score_input_kind.dart';
import 'package:scoard_game/application/models/scoring/value_picker_definition.dart';

class EnteredLineDefinition {
  const EnteredLineDefinition({
    required this.id,
    required this.label,
    required this.inputKind,
    required this.isEntered,
    required this.contributesToFinalResult,
    this.initialIntegerValue,
    this.minimumDisplayDigits = 1,
    this.enableQuickAdjust = false,
    this.enableTapToEdit = false,
    this.allowReplace = true,
    this.allowAdjust = false,
    this.valuePickers = const [],
    this.quickPickRange,
  }) : assert(minimumDisplayDigits > 0);

  final String id;
  final String label;
  final ScoreInputKind inputKind;
  final bool isEntered;
  final bool contributesToFinalResult;
  final int? initialIntegerValue;
  final int minimumDisplayDigits;
  final bool enableQuickAdjust;
  final bool enableTapToEdit;
  final bool allowReplace;
  final bool allowAdjust;

  /// Template-defined entry modes offered beside the calculator and quick
  /// pick.
  final List<ValuePickerDefinition> valuePickers;

  /// The values quick pick offers, such as 0–12, or null for the full
  /// grid. Only a quicker way to pick: other modes take any number.
  final (int, int)? quickPickRange;
}