import 'package:flutter/material.dart';
import 'package:scoard_game/application/models/scoring/marker_line_definition.dart';
import 'package:scoard_game/application/models/scoring/value_picker_definition.dart';
import 'package:scoard_game/application/models/scoring/value_picker_pick.dart';
import 'package:scoard_game/core/scoring/score_expression.dart';
import 'package:scoard_game/core/scoring/value_picker_total.dart';
import 'package:scoard_game/ui/score_input/quick_pick_grid.dart';
import 'package:scoard_game/ui/score_input/score_entry_mode.dart';
import 'package:scoard_game/ui/score_input/score_value_edit_action.dart';
import 'package:scoard_game/ui/score_input/score_value_edit_request.dart';
import 'package:scoard_game/ui/score_input/value_picker_pad.dart';

Future<ScoreValueEditRequest?> showNumericValuePicker(
  BuildContext context, {
  required String title,
  required int currentValue,
  bool hasCurrentValue = true,
  int? currentRoundScore,
  String? currentScoreSubLabel,
  required bool allowReplace,
  required bool allowAdjust,
  ScoreEntryMemory? entryMemory,
  List<ValuePickerDefinition> valuePickers = const [],
  ValuePickerPick? initialPick,
  List<MarkerLineDefinition> markers = const [],
  Set<String> activeMarkers = const {},
  void Function(String markerId, bool isSet)? onMarkerChanged,
}) {
  return showModalBottomSheet<ScoreValueEditRequest>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _NumericValuePicker(
      title: title,
      currentValue: currentValue,
      hasCurrentValue: hasCurrentValue,
      currentRoundScore: currentRoundScore,
      currentScoreSubLabel: currentScoreSubLabel,
      allowReplace: allowReplace,
      allowAdjust: allowAdjust,
      entryMemory: entryMemory ?? ScoreEntryMemory(),
      valuePickers: valuePickers,
      initialPick: initialPick,
      markers: markers,
      activeMarkers: activeMarkers,
      onMarkerChanged: onMarkerChanged,
    ),
  );
}

class _NumericValuePicker extends StatefulWidget {
  const _NumericValuePicker({
    required this.title,
    required this.currentValue,
    required this.hasCurrentValue,
    this.currentRoundScore,
    this.currentScoreSubLabel,
    required this.allowReplace,
    required this.allowAdjust,
    required this.entryMemory,
    required this.valuePickers,
    this.initialPick,
    this.markers = const [],
    this.activeMarkers = const {},
    this.onMarkerChanged,
  });

  final String title;
  final int currentValue;

  /// False when the player has no score yet; [currentValue] is then the
  /// starting value used for Adjust.
  final bool hasCurrentValue;

  /// What the current entry counts for when the template calculates the
  /// score (such as Skyjo doubling), or null.
  final int? currentRoundScore;

  /// The template's score sub label, such as "from 10", or null.
  final String? currentScoreSubLabel;
  final bool allowReplace;
  final bool allowAdjust;
  final ScoreEntryMemory entryMemory;

  /// Template-defined modes, offered before the built-in ones.
  final List<ValuePickerDefinition> valuePickers;

  /// Tiles the score was last entered with, to reopen the picker with them.
  final ValuePickerPick? initialPick;

  /// The template's per-round flags, such as "Went out first", with the
  /// ones set for this player. Toggling one takes effect immediately.
  final List<MarkerLineDefinition> markers;
  final Set<String> activeMarkers;
  final void Function(String markerId, bool isSet)? onMarkerChanged;

  @override
  State<_NumericValuePicker> createState() => _NumericValuePickerState();
}

class _NumericValuePickerState extends State<_NumericValuePicker> {
  static const _divideByZeroMessage = 'Can\'t divide by zero.';

  // Modes are keyed by name: a built-in mode's name, or "picker:<id>".
  late String _modeKey = _initialModeKey();
  ScoreExpression _expression = const ScoreExpression();
  int? _quickPickValue;

  /// Indexes of the value picker tiles tapped so far, in order. Starts with
  /// the tiles the score was last entered with, if any.
  late List<int> _pickedTiles = switch (_initialPickPicker) {
    final picker? => pickedIndexesFor(picker, widget.initialPick!),
    null => const [],
  };
  String? _errorText;
  late final Set<String> _activeMarkers = {...widget.activeMarkers};

  static String _pickerKey(String id) => 'picker:$id';

  /// "No score yet", "Current score: 10", or with the template's score sub
  /// label, "Current score: 20 (from 10)".
  String get _currentScoreText {
    if (!widget.hasCurrentValue) {
      return 'No score yet';
    }
    final score = widget.currentRoundScore ?? widget.currentValue;
    final subLabel = widget.currentScoreSubLabel;
    return subLabel == null
        ? 'Current score: $score'
        : 'Current score: $score ($subLabel)';
  }

  ValuePickerDefinition? get _initialPickPicker {
    final pickerId = widget.initialPick?.pickerId;
    return widget.valuePickers
        .where((picker) => picker.id == pickerId)
        .firstOrNull;
  }

  String _initialModeKey() {
    // A score entered with a picker reopens in that picker, ready to adjust.
    final initialPicker = _initialPickPicker;
    if (initialPicker != null) {
      return _pickerKey(initialPicker.id);
    }

    final memory = widget.entryMemory;
    final rememberedPickerId = memory.valuePickerId;
    if (rememberedPickerId != null &&
        widget.valuePickers.any((picker) => picker.id == rememberedPickerId)) {
      return _pickerKey(rememberedPickerId);
    }
    if (memory.mode != null) {
      return memory.mode!.name;
    }
    if (widget.valuePickers.isNotEmpty) {
      return _pickerKey(widget.valuePickers.first.id);
    }
    return ScoreEntryMode.calculator.name;
  }

  bool get _isCalculator => _modeKey == ScoreEntryMode.calculator.name;

  bool get _isQuickPick => _modeKey == ScoreEntryMode.quickPick.name;

  ValuePickerDefinition? get _activePicker => widget.valuePickers
      .where((picker) => _pickerKey(picker.id) == _modeKey)
      .firstOrNull;

  int? get _entryValue {
    if (_isCalculator) {
      return _expression.value;
    }
    if (_isQuickPick) {
      return _quickPickValue;
    }
    return _pickedTiles.isEmpty
        ? null
        : valuePickerTotal(_activePicker!, _pickedTiles);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final entryValue = _entryValue;
    final adjustedValue =
        entryValue == null ? null : widget.currentValue + entryValue;
    final errorText = _errorText ??
        (_isCalculator && _expression.dividesByZero
            ? _divideByZeroMessage
            : null);
    final activePicker = _activePicker;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, viewInsets + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: theme.textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _currentScoreText,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              SegmentedButton<String>(
                segments: [
                  for (final picker in widget.valuePickers)
                    ButtonSegment(
                      value: _pickerKey(picker.id),
                      icon: const Icon(Icons.style_outlined),
                      tooltip: picker.label,
                    ),
                  for (final mode in ScoreEntryMode.values)
                    ButtonSegment(
                      value: mode.name,
                      icon: Icon(mode.icon),
                      tooltip: mode.label,
                    ),
                ],
                selected: {_modeKey},
                showSelectedIcon: false,
                onSelectionChanged: (selection) => _setMode(selection.single),
              ),
            ],
          ),
          if (widget.markers.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final marker in widget.markers)
                  FilterChip(
                    label: Text(marker.label),
                    selected: _activeMarkers.contains(marker.id),
                    onSelected: (isSet) {
                      setState(() {
                        if (isSet) {
                          _activeMarkers.add(marker.id);
                        } else {
                          _activeMarkers.remove(marker.id);
                        }
                      });
                      widget.onMarkerChanged?.call(marker.id, isSet);
                    },
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          if (activePicker != null) ...[
            ValuePickerPad(
              definition: activePicker,
              picked: _pickedTiles,
              onAdd: (value) => setState(() {
                _errorText = null;
                _pickedTiles = [..._pickedTiles, value];
              }),
              onRemoveAt: (index) => setState(() {
                _errorText = null;
                _pickedTiles = [..._pickedTiles]..removeAt(index);
              }),
            ),
            if (errorText != null) _ErrorText(errorText),
          ] else if (_isCalculator) ...[
            _CalculatorDisplay(
              expression: _expression,
              label: widget.allowAdjust && !widget.allowReplace
                  ? 'Adjustment amount'
                  : 'Score value',
              hasError: errorText != null,
              onClear: () => _updateExpression(const ScoreExpression()),
            ),
            if (errorText != null) _ErrorText(errorText),
            const SizedBox(height: 18),
            _Numpad(
              onDigitPressed: (digit) =>
                  _updateExpression(_expression.appendDigit(digit)),
              onOperatorPressed: (operator) =>
                  _updateExpression(_expression.applyOperator(operator)),
              onBackspacePressed: () =>
                  _updateExpression(_expression.backspace()),
              onToggleSignPressed: () =>
                  _updateExpression(_expression.toggleSign()),
            ),
          ] else ...[
            QuickPickGrid(
              selectedValue: _quickPickValue,
              initialColumn: widget.entryMemory.quickPickColumn,
              onSelected: (value) => setState(() {
                _errorText = null;
                _quickPickValue = value;
              }),
            ),
            if (errorText != null) _ErrorText(errorText),
          ],
          const SizedBox(height: 18),
          // Adjust sits at the left and Replace, the more common choice, at
          // the right, spread apart so they are hard to mix up.
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: widget.allowAdjust
                  ? WrapAlignment.spaceBetween
                  : WrapAlignment.end,
              spacing: 10,
              runSpacing: 10,
              children: [
                if (widget.allowAdjust)
                  FilledButton.tonal(
                    onPressed: () => _submit(ScoreValueEditAction.add),
                    child: Text(
                      adjustedValue == null
                          ? 'Add to Existing'
                          : 'Adjust -> $adjustedValue',
                    ),
                  ),
                if (widget.allowReplace)
                  FilledButton(
                    onPressed: () => _submit(ScoreValueEditAction.replace),
                    child: Text(
                      entryValue == null ? 'Replace' : 'Replace -> $entryValue',
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _setMode(String modeKey) {
    final memory = widget.entryMemory;
    final picker = widget.valuePickers
        .where((picker) => _pickerKey(picker.id) == modeKey)
        .firstOrNull;
    if (picker != null) {
      memory.valuePickerId = picker.id;
      memory.mode = null;
    } else {
      memory.mode = ScoreEntryMode.values.byName(modeKey);
      memory.valuePickerId = null;
    }

    setState(() {
      if (modeKey != _modeKey) {
        _pickedTiles = const [];
      }
      _modeKey = modeKey;
      _errorText = null;
    });
  }

  void _submit(ScoreValueEditAction action) {
    final entryValue = _entryValue;

    if (entryValue == null) {
      setState(() {
        if (_isCalculator) {
          _errorText = _expression.dividesByZero
              ? _divideByZeroMessage
              : 'Enter a whole number.';
        } else if (_isQuickPick) {
          _errorText = 'Pick a number.';
        } else {
          _errorText = 'Tap at least one value.';
        }
      });
      return;
    }

    if (_isQuickPick) {
      widget.entryMemory.quickPickColumn = QuickPickGrid.columnOf(entryValue);
    }

    Navigator.of(context).pop(
      ScoreValueEditRequest(
        action: action,
        value: entryValue,
        entryPick: _activePicker == null
            ? null
            : valuePickerPickOf(_activePicker!, _pickedTiles),
      ),
    );
  }

  void _updateExpression(ScoreExpression expression) {
    setState(() {
      _errorText = null;
      _expression = expression;
    });
  }
}

class _CalculatorDisplay extends StatelessWidget {
  const _CalculatorDisplay({
    required this.expression,
    required this.label,
    required this.hasError,
    required this.onClear,
  });

  final ScoreExpression expression;
  final String label;
  final bool hasError;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: hasError ? theme.colorScheme.error : theme.dividerColor,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label, style: theme.textTheme.bodyMedium),
              ),
              if (!expression.isEmpty)
                TextButton(
                  onPressed: onClear,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('Clear'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // The calculation line only appears once an operator is used. The
          // sheet is anchored to the bottom, so it grows upward and the keys
          // stay where they are.
          AnimatedSize(
            duration: const Duration(milliseconds: 150),
            alignment: Alignment.bottomLeft,
            child: expression.hasOperator
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      expression.displayText,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          Text(
            expression.hasOperator
                ? '= ${expression.value ?? '?'}'
                : expression.displayText,
            style: theme.textTheme.displaySmall?.copyWith(fontSize: 38),
          ),
        ],
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}

class _Numpad extends StatelessWidget {
  const _Numpad({
    required this.onDigitPressed,
    required this.onOperatorPressed,
    required this.onBackspacePressed,
    required this.onToggleSignPressed,
  });

  final ValueChanged<String> onDigitPressed;
  final ValueChanged<ScoreOperator> onOperatorPressed;
  final VoidCallback onBackspacePressed;
  final VoidCallback onToggleSignPressed;

  @override
  Widget build(BuildContext context) {
    _NumpadKey digit(String value) =>
        _NumpadKey(label: value, onPressed: () => onDigitPressed(value));
    _NumpadKey operator(ScoreOperator value) => _NumpadKey(
          label: value.symbol,
          isOperator: true,
          onPressed: () => onOperatorPressed(value),
        );

    return Column(
      children: [
        _NumpadRow(
          children: [
            digit('7'),
            digit('8'),
            digit('9'),
            operator(ScoreOperator.divide),
          ],
        ),
        const SizedBox(height: 10),
        _NumpadRow(
          children: [
            digit('4'),
            digit('5'),
            digit('6'),
            operator(ScoreOperator.multiply),
          ],
        ),
        const SizedBox(height: 10),
        _NumpadRow(
          children: [
            digit('1'),
            digit('2'),
            digit('3'),
            operator(ScoreOperator.subtract),
          ],
        ),
        const SizedBox(height: 10),
        _NumpadRow(
          children: [
            _NumpadKey(label: '+/-', onPressed: onToggleSignPressed),
            digit('0'),
            _NumpadKey(
              icon: Icons.backspace_outlined,
              onPressed: onBackspacePressed,
            ),
            operator(ScoreOperator.add),
          ],
        ),
      ],
    );
  }
}

class _NumpadRow extends StatelessWidget {
  const _NumpadRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: children
          .map(
            (child) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: child,
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _NumpadKey extends StatelessWidget {
  const _NumpadKey({
    this.label,
    this.icon,
    this.isOperator = false,
    required this.onPressed,
  });

  final String? label;
  final IconData? icon;
  final bool isOperator;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 56,
      child: FilledButton.tonal(
        onPressed: onPressed,
        style: isOperator
            ? FilledButton.styleFrom(
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                textStyle: const TextStyle(fontSize: 24),
              )
            : null,
        child: icon != null ? Icon(icon) : Text(label!),
      ),
    );
  }
}
