import 'package:flutter/material.dart';
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
  String _rawDigits = '';
  bool _isNegative = false;
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final parsedValue = _parsedValue;
    final replaceResultValue = parsedValue;
    final adjustedResultValue = parsedValue == null
        ? null
        : widget.currentValue + parsedValue;

    return Padding(
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
                color: _errorText == null
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
                    if (_rawDigits.isNotEmpty || _isNegative)
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
                Text(
                  _displayValue,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontSize: 38,
                  ),
                ),
              ],
            ),
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorText!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 18),
          _Numpad(
            onDigitPressed: _appendDigit,
            onBackspacePressed: _backspace,
            onToggleSignPressed: _toggleSign,
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
                    replaceResultValue == null
                        ? 'Replace'
                        : 'Replace -> $replaceResultValue',
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
    final parsedValue = _parsedValue;

    if (parsedValue == null) {
      setState(() => _errorText = 'Enter a whole number.');
      return;
    }

    Navigator.of(context).pop(
      ScoreValueEditRequest(
        action: action,
        value: parsedValue,
      ),
    );
  }

  int? get _parsedValue {
    if (_rawDigits.isEmpty) {
      return null;
    }

    final magnitude = int.tryParse(_rawDigits);
    if (magnitude == null) {
      return null;
    }

    return _isNegative ? -magnitude : magnitude;
  }

  String get _displayValue {
    if (_rawDigits.isEmpty) {
      return _isNegative ? '-0' : '0';
    }

    return _isNegative ? '-$_rawDigits' : _rawDigits;
  }

  void _appendDigit(String digit) {
    setState(() {
      _errorText = null;
      if (_rawDigits == '0') {
        _rawDigits = digit;
      } else {
        _rawDigits += digit;
      }
    });
  }

  void _backspace() {
    setState(() {
      _errorText = null;
      if (_rawDigits.isNotEmpty) {
        _rawDigits = _rawDigits.substring(0, _rawDigits.length - 1);
      }
    });
  }

  void _clear() {
    setState(() {
      _errorText = null;
      _rawDigits = '';
      _isNegative = false;
    });
  }

  void _toggleSign() {
    setState(() {
      _errorText = null;
      _isNegative = !_isNegative;
    });
  }
}

class _Numpad extends StatelessWidget {
  const _Numpad({
    required this.onDigitPressed,
    required this.onBackspacePressed,
    required this.onToggleSignPressed,
  });

  final ValueChanged<String> onDigitPressed;
  final VoidCallback onBackspacePressed;
  final VoidCallback onToggleSignPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _NumpadRow(
          children: [
            _NumpadKey(label: '7', onPressed: () => onDigitPressed('7')),
            _NumpadKey(label: '8', onPressed: () => onDigitPressed('8')),
            _NumpadKey(label: '9', onPressed: () => onDigitPressed('9')),
          ],
        ),
        const SizedBox(height: 10),
        _NumpadRow(
          children: [
            _NumpadKey(label: '4', onPressed: () => onDigitPressed('4')),
            _NumpadKey(label: '5', onPressed: () => onDigitPressed('5')),
            _NumpadKey(label: '6', onPressed: () => onDigitPressed('6')),
          ],
        ),
        const SizedBox(height: 10),
        _NumpadRow(
          children: [
            _NumpadKey(label: '1', onPressed: () => onDigitPressed('1')),
            _NumpadKey(label: '2', onPressed: () => onDigitPressed('2')),
            _NumpadKey(label: '3', onPressed: () => onDigitPressed('3')),
          ],
        ),
        const SizedBox(height: 10),
        _NumpadRow(
          children: [
            _NumpadKey(label: '+/-', onPressed: onToggleSignPressed),
            _NumpadKey(label: '0', onPressed: () => onDigitPressed('0')),
            _NumpadKey(
              icon: Icons.backspace_outlined,
              onPressed: onBackspacePressed,
            ),
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
    required this.onPressed,
  });

  final String? label;
  final IconData? icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: FilledButton.tonal(
        onPressed: onPressed,
        child: icon != null ? Icon(icon) : Text(label!),
      ),
    );
  }
}