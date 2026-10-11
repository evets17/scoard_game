import 'package:flutter/material.dart';
import 'package:scoard_game/application/models/scoring/score_field_definition.dart';
import 'package:scoard_game/ui/score_input/numeric_value_picker.dart';
import 'package:scoard_game/ui/score_input/score_value_edit_action.dart';

class NumericScoreField extends StatefulWidget {
  const NumericScoreField({
    required this.label,
    required this.fieldDefinition,
    required this.controller,
    this.valueLabelBuilder,
    this.valueLabelMinimumDigits = 0,
    this.onLabelTap,
    this.onEditorClosed,
    super.key,
  });

  final String label;
  final ScoreFieldDefinition fieldDefinition;
  final TextEditingController controller;
  final String? Function(int currentValue)? valueLabelBuilder;
  final int valueLabelMinimumDigits;
  final VoidCallback? onLabelTap;
  final VoidCallback? onEditorClosed;

  @override
  State<NumericScoreField> createState() => _NumericScoreFieldState();
}

class _NumericScoreFieldState extends State<NumericScoreField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant NumericScoreField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      widget.controller.addListener(_handleControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentValue = int.tryParse(widget.controller.text.trim()) ??
        (widget.fieldDefinition.initialIntegerValue ?? 0);
    final valueLabel = widget.valueLabelBuilder?.call(currentValue);
    final scoreTextStyle = theme.textTheme.displaySmall?.copyWith(
      fontSize: 34,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final valueLabelTextStyle = theme.textTheme.titleLarge?.copyWith(
      fontSize: 20,
      color: theme.colorScheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onLabelTap,
                child: Text(
                  widget.label,
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 22),
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.fieldDefinition.enableQuickAdjust)
                  IconButton(
                    onPressed: () => _setValue(currentValue - 1),
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    tooltip: 'Decrease score',
                    visualDensity: VisualDensity.compact,
                  ),
                InkWell(
                  onTap: widget.fieldDefinition.enableTapToEdit
                      ? () => _openEditor(context, currentValue)
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: _minimumWidthForDigits(
                        context,
                        scoreTextStyle,
                        widget.fieldDefinition.minimumDisplayDigits,
                        horizontalPadding: 16,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Text(
                        '$currentValue',
                        textAlign: TextAlign.center,
                        style: scoreTextStyle,
                      ),
                    ),
                  ),
                ),
                if (widget.fieldDefinition.enableQuickAdjust)
                  IconButton(
                    onPressed: () => _setValue(currentValue + 1),
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    tooltip: 'Increase score',
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            if (valueLabel != null && valueLabel.isNotEmpty) ...[
              const SizedBox(width: 10),
              Container(
                constraints: BoxConstraints(
                  minWidth: _minimumWidthForDigits(
                    context,
                    valueLabelTextStyle,
                    widget.valueLabelMinimumDigits,
                    horizontalPadding: 20,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  valueLabel,
                  textAlign: TextAlign.center,
                  style: valueLabelTextStyle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, int currentValue) async {
    final request = await showNumericValuePicker(
      context,
      title: widget.label,
      currentValue: currentValue,
      allowReplace: widget.fieldDefinition.allowReplace,
      allowAdjust: widget.fieldDefinition.allowAdjust,
    );

    if (request == null) {
      return;
    }

    switch (request.action) {
      case ScoreValueEditAction.replace:
        _setValue(request.value);
      case ScoreValueEditAction.add:
        _setValue(currentValue + request.value);
    }

    widget.onEditorClosed?.call();
  }

  void _setValue(int value) {
    widget.controller.text = value.toString();
  }

  double _minimumWidthForDigits(
    BuildContext context,
    TextStyle? style,
    int minimumDigits,
    {double horizontalPadding = 0}
  ) {
    if (minimumDigits <= 0) {
      return 0;
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: List.filled(minimumDigits, '8').join(),
        style: style,
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();

    return textPainter.width + horizontalPadding;
  }
}