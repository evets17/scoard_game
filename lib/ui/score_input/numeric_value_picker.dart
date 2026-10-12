import 'package:flutter/material.dart';
import 'package:scoard_game/core/scoring/score_expression.dart';
import 'package:scoard_game/ui/score_input/quick_pick_grid.dart';
import 'package:scoard_game/ui/score_input/score_entry_mode.dart';
import 'package:scoard_game/ui/score_input/score_value_edit_action.dart';
import 'package:scoard_game/ui/score_input/score_value_edit_request.dart';

Future<ScoreValueEditRequest?> showNumericValuePicker(
  BuildContext context, {
  required String title,
  required int currentValue,
  required bool allowReplace,
  required bool allowAdjust,
  ScoreEntryMemory? entryMemory,
}) {
  return showModalBottomSheet<ScoreValueEditRequest>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _NumericValuePicker(
      title: title,
      currentValue: currentValue,
      allowReplace: allowReplace,
      allowAdjust: allowAdjust,
      entryMemory: entryMemory ?? ScoreEntryMemory(),
    ),
  );
}

class _NumericValuePicker extends StatefulWidget {
  const _NumericValuePicker({
    required this.title,
    required this.currentValue,
    required this.allowReplace,
    required this.allowAdjust,
    required this.entryMemory,
  });

  final String title;
  final int currentValue;
  final bool allowReplace;
  final bool allowAdjust;
  final ScoreEntryMemory entryMemory;

  @override
  State<_NumericValuePicker> createState() => _NumericValuePickerState();
}

class _NumericValuePickerState extends State<_NumericValuePicker> {
  static const _divideByZeroMessage = 'Can\'t divide by zero.';

  late ScoreEntryMode _mode = widget.entryMemory.mode;
  ScoreExpression _expression = const ScoreExpression();
  int? _quickPickValue;
  String? _errorText;

  int? get _entryValue => switch (_mode) {
        ScoreEntryMode.calculator => _expression.value,
        ScoreEntryMode.quickPick => _quickPickValue,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final entryValue = _entryValue;
    final adjustedValue =
        entryValue == null ? null : widget.currentValue + entryValue;
    final errorText = _errorText ??
        (_mode == ScoreEntryMode.calculator && _expression.dividesByZero
            ? _divideByZeroMessage
            : null);

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
                      'Current score: ${widget.currentValue}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              SegmentedButton<ScoreEntryMode>(
                segments: [
                  for (final mode in ScoreEntryMode.values)
                    ButtonSegment(
                      value: mode,
                      icon: Icon(mode.icon),
                      tooltip: mode.label,
                    ),
                ],
                selected: {_mode},
                showSelectedIcon: false,
                onSelectionChanged: (selection) => _setMode(selection.single),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_mode == ScoreEntryMode.calculator) ...[
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
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (widget.allowReplace)
                FilledButton(
                  onPressed: () => _submit(ScoreValueEditAction.replace),
                  child: Text(
                    entryValue == null ? 'Replace' : 'Replace -> $entryValue',
                  ),
                ),
              if (widget.allowAdjust)
                FilledButton.tonal(
                  onPressed: () => _submit(ScoreValueEditAction.add),
                  child: Text(
                    adjustedValue == null
                        ? 'Add to Existing'
                        : 'Adjust -> $adjustedValue',
                  ),
                ),
            ],
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _setMode(ScoreEntryMode mode) {
    widget.entryMemory.mode = mode;
    setState(() {
      _mode = mode;
      _errorText = null;
    });
  }

  void _submit(ScoreValueEditAction action) {
    final entryValue = _entryValue;

    if (entryValue == null) {
      setState(() {
        _errorText = switch (_mode) {
          ScoreEntryMode.calculator => _expression.dividesByZero
              ? _divideByZeroMessage
              : 'Enter a whole number.',
          ScoreEntryMode.quickPick => 'Pick a number.',
        };
      });
      return;
    }

    if (_mode == ScoreEntryMode.quickPick) {
      widget.entryMemory.quickPickColumn = QuickPickGrid.columnOf(entryValue);
    }

    Navigator.of(context).pop(
      ScoreValueEditRequest(
        action: action,
        value: entryValue,
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
