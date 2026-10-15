import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:scoard_game/application/models/scoring/card_text.dart';
import 'package:scoard_game/application/models/sessions/player_color.dart';
import 'package:scoard_game/ui/players/player_color_halo.dart';
import 'package:scoard_game/ui/score_input/value_picker_pad.dart';
import 'package:scoard_game/ui/theme/app_colors.dart';

/// A player's column on the score sheet.
class ScoreSheetPlayer {
  const ScoreSheetPlayer({
    required this.id,
    required this.name,
    required this.total,
    this.color,
    this.badges = const [],
  });

  final String id;
  final String name;

  /// Shown in the totals row.
  final int total;
  final PlayerColor? color;

  /// The player's badges for the selected row, shown in the header.
  final List<CardText> badges;
}

/// What one cell shows.
class ScoreSheetCell {
  const ScoreSheetCell({this.score, this.scoreLabel, this.scoreSubLabel});

  /// Nothing entered yet; shown as a dash.
  static const empty = ScoreSheetCell();

  final int? score;

  /// Shown instead of the score, such as "Bust".
  final CardText? scoreLabel;

  /// Shown small under the score, such as "from 10".
  final CardText? scoreSubLabel;
}

/// One row of the score sheet: a round, or later a line.
class ScoreSheetRow {
  const ScoreSheetRow({
    required this.label,
    required this.cells,
    this.selected = false,
  });

  /// Shown in the fixed first column, such as the round number.
  final String label;

  /// One per player, in column order.
  final List<ScoreSheetCell> cells;
  final bool selected;
}

/// The sheet view: rows down, players across, totals at the bottom.
///
/// The first column, the header row, and the totals row stay put; player
/// columns scroll sideways when they don't fit, and rows scroll up and
/// down. See `_specs/restart_slice_12_score_sheets_plan.md`, section 7.
class ScoreSheetGrid extends StatefulWidget {
  const ScoreSheetGrid({
    required this.players,
    required this.rows,
    this.totalLabel = 'Tot',
    this.onRowTap,
    this.onCellTap,
    super.key,
  });

  final List<ScoreSheetPlayer> players;
  final List<ScoreSheetRow> rows;
  final String totalLabel;

  /// Called with the row's index when its label is tapped, or a cell when
  /// there is no [onCellTap].
  final ValueChanged<int>? onRowTap;

  /// Called with the row's and player's index when a cell is tapped.
  final void Function(int row, int player)? onCellTap;

  @override
  State<ScoreSheetGrid> createState() => _ScoreSheetGridState();
}

const double _labelColumnWidth = 34;
const double _rowHeight = 40;

/// Columns at least this wide get horizontal names; narrower ones get
/// angled names.
const double _horizontalHeaderMinWidth = 64;
const double _angledHeaderMinWidth = 46;

const double _chipHeight = 16;
const double _chipGap = 2;
const double _underlineHeight = 3;

class _ScoreSheetGridState extends State<ScoreSheetGrid> {
  final _body = ScrollController();
  final _labels = ScrollController();
  final _columns = ScrollController();

  @override
  void initState() {
    super.initState();
    // The label column follows the body when rows scroll.
    _body.addListener(() {
      if (_labels.hasClients && _labels.offset != _body.offset) {
        _labels.jumpTo(_body.offset);
      }
    });
    _columns.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _showSelectedRow());
  }

  @override
  void didUpdateWidget(covariant ScoreSheetGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldSelected = oldWidget.rows.indexWhere((row) => row.selected);
    final selected = widget.rows.indexWhere((row) => row.selected);
    if (oldSelected != selected || oldWidget.rows.length != widget.rows.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showSelectedRow());
    }
  }

  @override
  void dispose() {
    _body.dispose();
    _labels.dispose();
    _columns.dispose();
    super.dispose();
  }

  /// Scrolls just enough to bring the selected row into view.
  void _showSelectedRow() {
    if (!mounted || !_body.hasClients) {
      return;
    }
    final index = widget.rows.indexWhere((row) => row.selected);
    if (index < 0) {
      return;
    }
    final position = _body.position;
    final top = index * _rowHeight;
    final bottom = top + _rowHeight;
    var offset = position.pixels;
    if (top < offset) {
      offset = top;
    } else if (bottom > offset + position.viewportDimension) {
      offset = bottom - position.viewportDimension;
    }
    _body.jumpTo(offset.clamp(0, position.maxScrollExtent));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);
    final gridColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.5);
    final selectedColor = palette.primaryAction.withValues(alpha: 0.18);

    return LayoutBuilder(
      builder: (context, constraints) {
        final players = widget.players;
        final available = constraints.maxWidth - _labelColumnWidth;
        final shared = players.isEmpty ? available : available / players.length;
        final angled = shared < _horizontalHeaderMinWidth;
        final columnWidth = math.max(
          angled ? _angledHeaderMinWidth : _horizontalHeaderMinWidth,
          shared,
        );
        final columnsWidth = columnWidth * players.length;
        final header = _headerLayout(
          context,
          players,
          columnWidth: columnWidth,
          angled: angled,
        );
        final scrolls = columnsWidth > available + 0.5;
        final moreToRight = scrolls &&
            (!_columns.hasClients ||
                _columns.offset < _columns.position.maxScrollExtent - 1);

        void tapRow(int index) => widget.onRowTap?.call(index);

        Widget labelCell(ScoreSheetRow row, int index) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => tapRow(index),
              child: Container(
                height: _rowHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: row.selected ? selectedColor : null,
                  border: Border(top: BorderSide(color: gridColor)),
                ),
                child: Text(
                  row.label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: row.selected
                        ? palette.primaryAction
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );

        Widget totalsLabel() => Container(
              height: _rowHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: gridColor, width: 2)),
              ),
              child: Text(
                widget.totalLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );

        final playerColumns = SizedBox(
          width: columnsWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: header.height,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final player in players)
                      _ColumnHeader(
                        player: player,
                        width: columnWidth,
                        angled: angled,
                        badgeArea: header.badgeArea,
                      ),
                  ],
                ),
              ),
              // Only as tall as the rows, so the totals follow straight
              // after them; the rows scroll once they don't fit.
              Flexible(
                child: ListView.builder(
                  controller: _body,
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: widget.rows.length,
                  itemExtent: _rowHeight,
                  itemBuilder: (context, index) {
                    final row = widget.rows[index];
                    return Row(
                      children: [
                        for (final (column, cell) in row.cells.indexed)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => widget.onCellTap != null
                                ? widget.onCellTap!(index, column)
                                : tapRow(index),
                            child: _Cell(
                              cell: cell,
                              width: columnWidth,
                              selected: row.selected,
                              selectedColor: selectedColor,
                              gridColor: gridColor,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                children: [
                  for (final player in players)
                    Container(
                      width: columnWidth,
                      height: _rowHeight,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        border: Border(
                          top: BorderSide(color: gridColor, width: 2),
                          left: BorderSide(color: gridColor),
                        ),
                      ),
                      child: Text(
                        '${player.total}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: _labelColumnWidth,
              child: Column(
                children: [
                  SizedBox(height: header.height),
                  Flexible(
                    child: ListView.builder(
                      controller: _labels,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: widget.rows.length,
                      itemExtent: _rowHeight,
                      itemBuilder: (context, index) =>
                          labelCell(widget.rows[index], index),
                    ),
                  ),
                  totalsLabel(),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: SingleChildScrollView(
                      controller: _columns,
                      scrollDirection: Axis.horizontal,
                      // Angled names rise past their column; let the last
                      // one show rather than cut it at the column edge.
                      clipBehavior: Clip.hardEdge,
                      child: playerColumns,
                    ),
                  ),
                  if (moreToRight)
                    Positioned(
                      top: 0,
                      bottom: 0,
                      right: 0,
                      width: 28,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.scaffoldBackgroundColor
                                    .withValues(alpha: 0),
                                theme.scaffoldBackgroundColor,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

TextStyle? _nameStyle(ThemeData theme) =>
    theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, height: 1.1);

/// The header's height, tall enough for every player's name and badges and
/// no taller (it grows with the most badges anyone has in the selected row),
/// and the height of the badge area under the names. Every column gets the
/// same badge area, so names line up whether or not a player has badges.
({double height, double badgeArea}) _headerLayout(
  BuildContext context,
  List<ScoreSheetPlayer> players, {
  required double columnWidth,
  required bool angled,
}) {
  final style = _nameStyle(Theme.of(context));
  final textScaler = MediaQuery.textScalerOf(context);

  TextPainter measure(String text, {int? maxLines, double? maxWidth}) =>
      TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: textScaler,
        maxLines: maxLines,
        ellipsis: '…',
      )..layout(maxWidth: maxWidth ?? double.infinity);

  var nameHeight = 0.0;
  var badgeLines = 0;
  for (final player in players) {
    if (angled) {
      final name = measure(player.name);
      // Rotated 45° about the start of the name.
      nameHeight = math.max(
        nameHeight,
        (name.width + name.height) * math.sqrt1_2 + 4,
      );
      badgeLines = math.max(badgeLines, player.badges.length);
    } else {
      final name = measure(player.name, maxLines: 2, maxWidth: columnWidth - 6);
      nameHeight = math.max(nameHeight, name.height);
      badgeLines = math.max(
        badgeLines,
        _wrappedBadgeLines(context, player.badges, columnWidth - 6),
      );
    }
  }

  final badgeArea =
      badgeLines == 0 ? 0.0 : 4 + badgeLines * (_chipHeight + _chipGap);
  return (
    height: 6 + nameHeight + badgeArea + 3 + _underlineHeight,
    badgeArea: badgeArea,
  );
}

/// How many lines [badges] wrap onto in [width].
int _wrappedBadgeLines(
  BuildContext context,
  List<CardText> badges,
  double width,
) {
  if (badges.isEmpty) {
    return 0;
  }
  var lines = 1;
  var used = 0.0;
  for (final badge in badges) {
    final chipWidth = _chipWidth(context, badge.text);
    if (used > 0 && used + _chipGap + chipWidth > width) {
      lines += 1;
      used = chipWidth;
    } else {
      used += (used > 0 ? _chipGap : 0) + chipWidth;
    }
  }
  return lines;
}

double _chipWidth(BuildContext context, String text) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: _chipTextStyle),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  )..layout();
  return painter.width + 10;
}

const _chipTextStyle = TextStyle(
  fontSize: 10,
  fontWeight: FontWeight.w700,
  height: 1.1,
);

class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader({
    required this.player,
    required this.width,
    required this.angled,
    required this.badgeArea,
  });

  final ScoreSheetPlayer player;
  final double width;
  final bool angled;

  /// Height kept for badges under the name, the same in every column.
  final double badgeArea;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = _nameStyle(theme);
    final chips = [for (final badge in player.badges) _Chip(badge: badge)];

    final Widget name;
    final Widget badges;
    if (angled) {
      // Rises to the right from just right of the column's middle.
      name = Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: width / 2 - 4,
            bottom: 2,
            child: Transform.rotate(
              angle: -math.pi / 4,
              alignment: Alignment.centerLeft,
              child: Text(player.name, maxLines: 1, style: style),
            ),
          ),
        ],
      );
      // One per line, so each badge stays in its own column.
      badges = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final chip in chips)
            Padding(
              padding: const EdgeInsets.only(top: _chipGap),
              child: chip,
            ),
        ],
      );
    } else {
      name = Align(
        alignment: Alignment.bottomCenter,
        child: Text(
          player.name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      );
      badges = Wrap(
        alignment: WrapAlignment.center,
        spacing: _chipGap,
        runSpacing: _chipGap,
        children: chips,
      );
    }

    return Tooltip(
      message: player.name,
      child: SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Column(
            children: [
              Expanded(child: name),
              if (badgeArea > 0)
                SizedBox(
                  height: badgeArea,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: badges,
                  ),
                ),
              const SizedBox(height: 3),
              Container(
                height: _underlineHeight,
                color: player.color?.swatch ??
                    theme.colorScheme.outlineVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.badge});

  final CardText badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background =
        parseTileColor(badge.color) ?? theme.colorScheme.secondaryContainer;
    final foreground =
        background.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
    return Container(
      height: _chipHeight,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          badge.text,
          maxLines: 1,
          style: _chipTextStyle.copyWith(color: foreground),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.cell,
    required this.width,
    required this.selected,
    required this.selectedColor,
    required this.gridColor,
  });

  final ScoreSheetCell cell;
  final double width;
  final bool selected;
  final Color selectedColor;
  final Color gridColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = cell.score;
    final scoreLabel = cell.scoreLabel;
    final subLabel = cell.scoreSubLabel;

    final Widget content;
    if (score == null) {
      content = Text(
        '–',
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      );
    } else if (scoreLabel != null) {
      content = Text(
        scoreLabel.text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: parseTileColor(scoreLabel.color),
        ),
      );
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$score',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.05,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (subLabel != null)
            Text(
              subLabel.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9.5,
                height: 1,
                color: parseTileColor(subLabel.color) ??
                    theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      );
    }

    return Container(
      width: width,
      height: _rowHeight,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: selected ? selectedColor : null,
        border: Border(
          top: BorderSide(color: gridColor),
          left: BorderSide(color: gridColor),
        ),
      ),
      child: content,
    );
  }
}
