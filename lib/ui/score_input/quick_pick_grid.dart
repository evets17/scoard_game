import 'package:flutter/material.dart';

/// Columns of numbers to tap: −1…−10, then 0–9, 10–19 … 90–99.
class QuickPickGrid extends StatefulWidget {
  const QuickPickGrid({
    required this.selectedValue,
    required this.onSelected,
    this.initialColumn,
    super.key,
  });

  static const int columnCount = 11;
  static const int rowCount = 10;

  final int? selectedValue;
  final ValueChanged<int?> onSelected;

  /// The column to center when the grid opens. Defaults to 0–9.
  final int? initialColumn;

  static int valueAt({required int column, required int row}) {
    return column == 0 ? -(row + 1) : (column - 1) * 10 + row;
  }

  static int columnOf(int value) => value < 0 ? 0 : value ~/ 10 + 1;

  @override
  State<QuickPickGrid> createState() => _QuickPickGridState();
}

class _QuickPickGridState extends State<QuickPickGrid> {
  static const double _targetColumnWidth = 56;
  static const double _gap = 4;

  ScrollController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Give the ten rows half of the usable screen height so the whole sheet
    // fits without scrolling, within limits that keep buttons tappable.
    final usableHeight = MediaQuery.sizeOf(context).height -
        MediaQuery.paddingOf(context).vertical;
    final rowHeight =
        ((usableHeight * 0.5 - _gap * (QuickPickGrid.rowCount - 1)) /
                QuickPickGrid.rowCount)
            .clamp(28.0, 44.0);
    final gridHeight = rowHeight * QuickPickGrid.rowCount +
        _gap * (QuickPickGrid.rowCount - 1);

    return SizedBox(
      height: gridHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          // Whole columns plus half of the next one, so it's clear the grid
          // scrolls sideways.
          final wholeColumns =
              (width / _targetColumnWidth - 0.5).floor().clamp(3, 8);
          final columnWidth = width / (wholeColumns + 0.5);
          _controller ??= ScrollController(
            initialScrollOffset: _initialOffset(width, columnWidth),
          );

          return ListView.builder(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            physics: _ColumnSnapPhysics(columnWidth: columnWidth),
            itemExtent: columnWidth,
            itemCount: QuickPickGrid.columnCount,
            itemBuilder: (context, column) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: _gap / 2),
              child: Column(
                children: [
                  for (var row = 0; row < QuickPickGrid.rowCount; row++) ...[
                    if (row > 0) const SizedBox(height: _gap),
                    SizedBox(
                      height: rowHeight,
                      width: double.infinity,
                      child: _QuickPickKey(
                        value: QuickPickGrid.valueAt(column: column, row: row),
                        selectedValue: widget.selectedValue,
                        onSelected: widget.onSelected,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  double _initialOffset(double width, double columnWidth) {
    final column = widget.initialColumn ?? 1;
    final maxOffset = columnWidth * QuickPickGrid.columnCount - width;
    final centered = (column + 0.5) * columnWidth - width / 2;
    final snapped = (centered / columnWidth).round() * columnWidth;
    return snapped.clamp(0.0, maxOffset < 0 ? 0.0 : maxOffset);
  }
}

class _QuickPickKey extends StatelessWidget {
  const _QuickPickKey({
    required this.value,
    required this.selectedValue,
    required this.onSelected,
  });

  final int value;
  final int? selectedValue;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selectedValue;
    final style = FilledButton.styleFrom(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      textStyle: const TextStyle(
        fontSize: 17,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
    final label = Text('$value');

    // Tapping the selected number again clears the selection.
    return isSelected
        ? FilledButton(
            onPressed: () => onSelected(null),
            style: style,
            child: label,
          )
        : FilledButton.tonal(
            onPressed: () => onSelected(value),
            style: style,
            child: label,
          );
  }
}

/// Lets a swipe glide across several columns and settle on a column edge.
class _ColumnSnapPhysics extends ScrollPhysics {
  const _ColumnSnapPhysics({required this.columnWidth, super.parent});

  final double columnWidth;

  @override
  _ColumnSnapPhysics applyTo(ScrollPhysics? ancestor) {
    return _ColumnSnapPhysics(
      columnWidth: columnWidth,
      parent: buildParent(ancestor),
    );
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final outOfRange = position.pixels < position.minScrollExtent ||
        position.pixels > position.maxScrollExtent;
    if (outOfRange) {
      return super.createBallisticSimulation(position, velocity);
    }

    final projected = position.pixels + velocity * 0.3;
    final target = ((projected / columnWidth).round() * columnWidth)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    final tolerance = toleranceFor(position);
    if ((target - position.pixels).abs() < tolerance.distance &&
        velocity.abs() < tolerance.velocity) {
      return null;
    }

    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }
}
