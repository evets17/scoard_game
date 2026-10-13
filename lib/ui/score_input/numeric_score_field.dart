import 'package:flutter/material.dart';
import 'package:scoard_game/application/models/scoring/marker_field_definition.dart';
import 'package:scoard_game/application/models/scoring/score_field_definition.dart';
import 'package:scoard_game/application/models/scoring/score_row_label.dart';
import 'package:scoard_game/application/models/scoring/value_picker_definition.dart';
import 'package:scoard_game/application/models/scoring/value_picker_pick.dart';
import 'package:scoard_game/core/scoring/value_picker_total.dart';
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
    this.entryPick,
    this.markers = const [],
    this.activeMarkers = const {},
    this.onMarkerChanged,
    this.roundScore,
    this.onEntryPickChanged,
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

  /// The value picker tiles the score was entered with, if any. Reopening
  /// the entry sheet starts with them, and row labels such as "Bust" come
  /// from them.
  final ValuePickerPick? entryPick;

  /// Called when an edit sets or clears [entryPick].
  final ValueChanged<ValuePickerPick?>? onEntryPickChanged;

  /// The template's per-round flags and the ones set for this player,
  /// shown as badges and toggled in the entry sheet.
  final List<MarkerFieldDefinition> markers;
  final Set<String> activeMarkers;
  final void Function(String markerId, bool isSet)? onMarkerChanged;

  /// The score this entry counts for, when the template calculates it (such
  /// as Skyjo doubling). Shown as the main number, with the entered value
  /// underneath when they differ. Null shows the entered value.
  final int? roundScore;

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

/// Font sizes for labels shown instead of the score. The score number keeps
/// its own size; these only apply while a label is showing.
double _rowLabelFontSize(RowLabelSize size) => switch (size) {
      RowLabelSize.small => 18,
      RowLabelSize.medium => 23,
      RowLabelSize.large => 28,
    };

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
    final rowLabel = _rowLabel;
    final badges = [
      for (final marker in widget.markers)
        if (widget.activeMarkers.contains(marker.id))
          ScoreRowLabel(text: marker.badge, color: marker.color),
      if (!isEmpty) ..._badges,
    ];
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
                child: badges.isEmpty
                    ? Text(widget.label, style: _labelTextStyle(theme))
                    : Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.label,
                              style: _labelTextStyle(theme),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          for (final badge in badges) ...[
                            const SizedBox(width: 6),
                            _ScoreBadge(badge: badge),
                          ],
                        ],
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: _scoreVerticalPadding,
                      ),
                      // A dash means nothing has been entered yet; it still
                      // counts as the starting value if play moves on.
                      child: !isEmpty && rowLabel != null
                          ? Semantics(
                              label: '${rowLabel.text}, score '
                                  '$currentValue',
                              excludeSemantics: true,
                              child: Text(
                                rowLabel.text,
                                textAlign: TextAlign.center,
                                style: scoreTextStyle?.copyWith(
                                  fontSize: _rowLabelFontSize(rowLabel.size),
                                  color: parseTileColor(rowLabel.color),
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
                          : _ScoreNumber(
                              enteredValue: currentValue,
                              roundScore: widget.roundScore,
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
      currentRoundScore: widget.roundScore,
      allowReplace: widget.fieldDefinition.allowReplace,
      allowAdjust: widget.fieldDefinition.allowAdjust,
      entryMemory: widget.entryMemory,
      valuePickers: widget.fieldDefinition.valuePickers,
      initialPick: widget.entryPick,
      markers: widget.markers,
      activeMarkers: widget.activeMarkers,
      onMarkerChanged: widget.onMarkerChanged,
    );

    if (request == null) {
      return;
    }

    switch (request.action) {
      case ScoreValueEditAction.replace:
        _setValue(request.value, entryPick: request.entryPick);
      case ScoreValueEditAction.add:
        // Added tiles no longer describe the whole score, so none are kept.
        _setValue(currentValue + request.value);
    }

    widget.onEditorClosed?.call();
  }

  /// Sets the score. Only a value picker's Replace keeps the tiles it came
  /// from; every other edit drops them. The change is reported first so it
  /// is saved together with the new value.
  void _setValue(int value, {ValuePickerPick? entryPick}) {
    if (entryPick != widget.entryPick) {
      widget.onEntryPickChanged?.call(entryPick);
    }
    widget.controller.text = value.toString();
  }

  /// The value picker behind the score and the tiles picked in it, if any.
  (ValuePickerDefinition, List<int>)? get _pickedTiles {
    final pick = widget.entryPick;
    if (pick == null) {
      return null;
    }
    final picker = widget.fieldDefinition.valuePickers
        .where((picker) => picker.id == pick.pickerId)
        .firstOrNull;
    return picker == null ? null : (picker, pickedIndexesFor(picker, pick));
  }

  /// The row label (such as "Bust") shown instead of the score.
  ScoreRowLabel? get _rowLabel => switch (_pickedTiles) {
        (final picker, final picked) => valuePickerRowLabel(picker, picked),
        null => null,
      };

  /// Badges (such as "7!") shown beside the player's name.
  List<ScoreRowLabel> get _badges => switch (_pickedTiles) {
        (final picker, final picked) => valuePickerBadges(picker, picked),
        null => const [],
      };

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
/// A small marker beside a player's name, such as "7!".
class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.badge});

  final ScoreRowLabel badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background =
        parseTileColor(badge.color) ?? theme.colorScheme.secondaryContainer;
    final foreground =
        background.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

    return Semantics(
      label: badge.text,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          badge.text,
          style: theme.textTheme.labelMedium?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// The main number on a score row: the round score, with the entered value
/// underneath when a template's calculation makes them differ ("8" over
/// "from 4"). -/+ and the entry sheet still change the entered value.
class _ScoreNumber extends StatelessWidget {
  const _ScoreNumber({
    required this.enteredValue,
    required this.roundScore,
    required this.style,
  });

  final int enteredValue;
  final int? roundScore;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final shown = roundScore ?? enteredValue;
    if (shown == enteredValue) {
      return Text('$enteredValue', textAlign: TextAlign.center, style: style);
    }

    final theme = Theme.of(context);
    return Semantics(
      label: '$shown, from $enteredValue',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$shown', textAlign: TextAlign.center, style: style),
          Text(
            'from $enteredValue',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
