import 'package:flutter/material.dart';
import 'package:scoard_game/core/scoring/score_expression.dart';
import 'package:scoard_game/ui/score_input/score_value_edit_action.dart';
import 'package:scoard_game/ui/score_input/score_value_edit_request.dart';

Future<ScoreValueEditRequest?> showNumericValuePicker(
  BuildContext context, {
  required String title,
  required int currentValue,
  required bool allowReplace,
  required bool allowAdjust,
}) {
  return showModalBottomSheet<ScoreValueEditRequest>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _NumericValuePicker(
      title: title,
      currentValue: currentValue,
      allowReplace: allowReplace,
      allowAdjust: allowAdjust,
    ),
  );
}

class _NumericValuePicker extends StatefulWidget {
  const _NumericValuePicker({
    required this.title,
    required this.currentValue,
    required this.allowReplace,
    required this.allowAdjust,
  });

  final String title;
  final int currentValue;
  final bool allowReplace;
  final bool allowAdjust;

  @override
  State<_NumericValuePicker> createState() => _NumericValuePickerState();
}

class _NumericValuePickerState extends State<_NumericValuePicker> {
  static const _divideByZeroMessage = 'Can\'t divide by zero.';

  ScoreExpression _expression = const ScoreExpression();
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final resultValue = _expression.value;
    final adjustedResultValue =
        resultValue == null ? null : widget.currentValue + resultValue;
    final errorText = _errorText ??
        (_expression.dividesByZero ? _divideByZeroMessage : null);
    final valueTextStyle = theme.textTheme.displaySmall?.copyWith(
      fontSize: 38,
    );

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, viewInsets + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Current score: ${widget.currentValue}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: errorText == null
                    ? theme.dividerColor
                    : theme.colorScheme.error,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.allowAdjust && !widget.allowReplace
                            ? 'Adjustment amount'
                            : 'Score value',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    if (!_expression.isEmpty)
                      TextButton(
                        onPressed: _clear,
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text('Clear'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // The calculation line only appears once an operator is used.
                // The sheet is anchored to the bottom, so it grows upward and
                // the keys stay where they are.
                AnimatedSize(
                  duration: const Duration(milliseconds: 150),
                  alignment: Alignment.bottomLeft,
                  child: _expression.hasOperator
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            _expression.displayText,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
                Text(
                  _expression.hasOperator
                      ? '= ${resultValue ?? '?'}'
                      : _expression.displayText,
                  style: valueTextStyle,
                ),
              ],
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 8),
            Text(
              errorText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 18),
          _Numpad(
            onDigitPressed: (digit) => _update(_expression.appendDigit(digit)),
            onOperatorPressed: (operator) =>
                _update(_expression.applyOperator(operator)),
            onBackspacePressed: () => _update(_expression.backspace()),
            onToggleSignPressed: () => _update(_expression.toggleSign()),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (widget.allowReplace)
                FilledButton(
                  onPressed: () => _submit(ScoreValueEditAction.replace),
                  child: Text(
                    resultValue == null ? 'Replace' : 'Replace -> $resultValue',
                  ),
                ),
              if (widget.allowAdjust)
                FilledButton.tonal(
                  onPressed: () => _submit(ScoreValueEditAction.add),
                  child: Text(
                    adjustedResultValue == null
                        ? 'Add to Existing'
                        : 'Adjust -> $adjustedResultValue',
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

  void _submit(ScoreValueEditAction action) {
    final resultValue = _expression.value;

    if (resultValue == null) {
      setState(() {
        _errorText = _expression.dividesByZero
            ? _divideByZeroMessage
            : 'Enter a whole number.';
      });
      return;
    }

    Navigator.of(context).pop(
      ScoreValueEditRequest(
        action: action,
        value: resultValue,
      ),
    );
  }

  void _update(ScoreExpression expression) {
    setState(() {
      _errorText = null;
      _expression = expression;
    });
  }

  void _clear() => _update(const ScoreExpression());
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
