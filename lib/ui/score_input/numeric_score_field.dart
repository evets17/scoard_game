import 'package:flutter/material.dart';
import 'package:scoard_game/application/models/scoring/score_field_definition.dart';
import 'package:scoard_game/application/models/scoring/score_row_label.dart';
import 'package:scoard_game/ui/score_input/numeric_value_picker.dart';
import 'package:scoard_game/ui/score_input/score_entry_mode.dart';
import 'package:scoard_game/ui/score_input/score_value_edit_action.dart';
import 'package:scoard_game/ui/score_input/value_picker_pad.dart';

class NumericScoreField extends StatefulWidget {
  const NumericScoreField({
    required this.label,
    required this.fieldDefinition,
    required this.controller,
    this.valueLabelBuilder,
    this.valueLabelMinimumDigits = 0,
    this.onLabelTap,
    this.onEditorClosed,
    this.rowLabel,
    this.onRowLabelChanged,
    this.compact = false,
    this.entryMemory,
    super.key,
  });

  final String label;
  final ScoreFieldDefinition fieldDefinition;
  final TextEditingController controller;
  final String? Function(int currentValue)? valueLabelBuilder;
  final int valueLabelMinimumDigits;
  final VoidCallback? onLabelTap;
  final VoidCallback? onEditorClosed;

  /// Shown instead of the score, such as "Bust", until the score is changed
  /// some other way.
  final ScoreRowLabel? rowLabel;

  /// Called when an edit sets or clears [rowLabel].
  final ValueChanged<ScoreRowLabel?>? onRowLabelChanged;

  /// Tighter spacing for long player lists.
  final bool compact;

  /// Shared by the rows of one game so the entry sheet remembers its mode.
  final ScoreEntryMemory? entryMemory;

  /// Whether [rowCount] rows at normal spacing would overflow
  /// [availableHeight]. Deciding from the normal height (not the current one)
  /// keeps the choice from flipping back and forth.
  static bool shouldUseCompact(
    BuildContext context, {
    required int rowCount,
    required double availableHeight,
    required ScoreFieldDefinition fieldDefinition,
    bool hasValueLabel = false,
  }) {
    final rowHeight = _normalRowHeight(
      context,
      fieldDefinition: fieldDefinition,
      hasValueLabel: hasValueLabel,
    );
    return rowCount * rowHeight > availableHeight;
  }

  // Worked out from the row's own text styles so larger system text counts.
  // Long names that wrap make rows taller than this, which only means a
  // slightly overflowing list keeps normal spacing.
  static double _normalRowHeight(
    BuildContext context, {
    required ScoreFieldDefinition fieldDefinition,
    required bool hasValueLabel,
  }) {
    final theme = Theme.of(context);
    final textScaler = MediaQuery.textScalerOf(context);

    double lineHeight(TextStyle? style) {
      final painter = TextPainter(
        text: TextSpan(text: '0', style: style),
        textDirection: Directionality.of(context),
        textScaler: textScaler,
      )..layout();
      return painter.height;
    }

    final contentHeights = [
      lineHeight(_labelTextStyle(theme)),
      lineHeight(_scoreTextStyle(theme)) + _scoreVerticalPadding * 2,
      if (fieldDefinition.enableQuickAdjust) _compactIconButtonSize,
      if (hasValueLabel)
        lineHeight(_valueLabelTextStyle(theme)) + _valueLabelVerticalPadding * 2,
    ];
    final contentHeight = contentHeights.reduce((a, b) => a > b ? a : b);

    return contentHeight +
        _normalSpacing.verticalPadding * 2 +
        _normalSpacing.bottomMargin;
  }

  @override
  State<NumericScoreField> createState() => _NumericScoreFieldState();
}

typedef _RowSpacing = ({double verticalPadding, double bottomMargin});

const _RowSpacing _normalSpacing = (verticalPadding: 10, bottomMargin: 12);
const _RowSpacing _compactSpacing = (verticalPadding: 2, bottomMargin: 4);
const double _scoreVerticalPadding = 6;
const double _valueLabelVerticalPadding = 8;
const double _compactIconButtonSize = 40;

/// Shown in place of a score that has not been entered yet.
const emptyScoreText = '–';

TextStyle? _labelTextStyle(ThemeData theme) =>
    theme.textTheme.titleLarge?.copyWith(fontSize: 22);

TextStyle? _scoreTextStyle(ThemeData theme) =>
    theme.textTheme.displaySmall?.copyWith(
      fontSize: 34,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

TextStyle? _valueLabelTextStyle(ThemeData theme) =>
    theme.textTheme.titleLarge?.copyWith(
      fontSize: 20,
      color: theme.colorScheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

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
    final isEmpty = widget.controller.text.trim().isEmpty;
    final currentValue = int.tryParse(widget.controller.text.trim()) ??
        (widget.fieldDefinition.initialIntegerValue ?? 0);
    final valueLabel = widget.valueLabelBuilder?.call(currentValue);
    final scoreTextStyle = _scoreTextStyle(theme);
    final valueLabelTextStyle = _valueLabelTextStyle(theme);
    final spacing = widget.compact ? _compactSpacing : _normalSpacing;

    return Card(
      margin: EdgeInsets.only(bottom: spacing.bottomMargin),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: spacing.verticalPadding,
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onLabelTap,
                child: Text(widget.label, style: _labelTextStyle(theme)),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: _scoreVerticalPadding,
                      ),
                      // A dash means nothing has been entered yet; it still
                      // counts as the starting value if play moves on.
                      child: !isEmpty && widget.rowLabel != null
                          ? Semantics(
                              label: '${widget.rowLabel!.text}, score '
                                  '$currentValue',
                              excludeSemantics: true,
                              child: Text(
                                widget.rowLabel!.text,
                                textAlign: TextAlign.center,
                                style: scoreTextStyle?.copyWith(
                                  fontSize: 28,
                                  color: parseTileColor(widget.rowLabel!.color),
                                ),
                              ),
                            )
                          : isEmpty
                          ? Semantics(
                              label: 'No score yet',
                              excludeSemantics: true,
                              child: Text(
                                emptyScoreText,
                                textAlign: TextAlign.center,
                                style: scoreTextStyle?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            )
                          : Text(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: _valueLabelVerticalPadding,
                ),
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
      hasCurrentValue: widget.controller.text.trim().isNotEmpty,
      allowReplace: widget.fieldDefinition.allowReplace,
      allowAdjust: widget.fieldDefinition.allowAdjust,
      entryMemory: widget.entryMemory,
      valuePickers: widget.fieldDefinition.valuePickers,
    );

    if (request == null) {
      return;
    }

    switch (request.action) {
      case ScoreValueEditAction.replace:
        _setValue(request.value, rowLabel: request.rowLabel);
      case ScoreValueEditAction.add:
        _setValue(currentValue + request.value, rowLabel: request.rowLabel);
    }

    widget.onEditorClosed?.call();
  }

  /// Sets the score. Any edit replaces the row label: a value picker may
  /// supply a new one, and every other edit clears it. The label is reported
  /// first so it is saved together with the new value.
  void _setValue(int value, {ScoreRowLabel? rowLabel}) {
    if (rowLabel != widget.rowLabel) {
      widget.onRowLabelChanged?.call(rowLabel);
    }
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