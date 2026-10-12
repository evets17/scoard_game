import 'package:flutter/material.dart';
import 'package:scoard_game/application/models/scoring/value_picker_definition.dart';
import 'package:scoard_game/core/scoring/value_picker_total.dart';

/// Tap the values in front of a player (such as Skyjo cards) to work out
/// their score.
///
/// [picked] holds the tapped tiles, as indexes into the picker's options, in
/// the order they were tapped. The picked tiles sit above the tile grid, so
/// the grid stays put as the list grows.
class ValuePickerPad extends StatelessWidget {
  const ValuePickerPad({
    required this.definition,
    required this.picked,
    required this.onAdd,
    required this.onRemoveAt,
    super.key,
  });

  final ValuePickerDefinition definition;
  final List<int> picked;

  /// Called with the index of the tapped tile.
  final ValueChanged<int> onAdd;

  /// Called with the position in [picked] to take back.
  final ValueChanged<int> onRemoveAt;

  static const double _gap = 6;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = definition.options;
    final total = valuePickerTotal(definition, picked);
    // Larger pickers use shorter tiles so the sheet still fits a phone.
    final tileHeight = options.length > 15 ? 46.0 : 52.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(definition.label, style: theme.textTheme.titleMedium),
            ),
            Text(
              picked.isEmpty ? '' : '= $total',
              style: theme.textTheme.headlineSmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 38),
          child: picked.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Text(
                    'Tap each one below. Tap one here to take it back.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (var position = 0; position < picked.length; position++)
                      _ValueTile(
                        option: options[picked[position]],
                        width: options[picked[position]].displayText.length > 3
                            ? 40
                            : 28,
                        height: 38,
                        compact: true,
                        tooltip:
                            'Remove ${options[picked[position]].displayText}',
                        onTap: () => onRemoveAt(position),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = (constraints.maxWidth / 60).floor().clamp(4, 8);
            final tileWidth =
                (constraints.maxWidth - _gap * (columns - 1)) / columns;

            // One flowing grid: grouped tiles sit next to each other in
            // template order and are told apart by colour, so a small group
            // like ×2 does not take a whole row.
            return Wrap(
              spacing: _gap,
              runSpacing: _gap,
              children: [
                for (var index = 0; index < options.length; index++)
                  _ValueTile(
                    option: options[index],
                    width: tileWidth,
                    height: options[index].label == null
                        ? tileHeight
                        : tileHeight + 8,
                    count: picked.where((p) => p == index).length,
                    onTap: () => onAdd(index),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ValueTile extends StatelessWidget {
  const _ValueTile({
    required this.option,
    required this.width,
    required this.height,
    required this.onTap,
    this.count = 0,
    this.compact = false,
    this.tooltip,
  });

  final ValuePickerOption option;
  final double width;
  final double height;
  final VoidCallback onTap;
  final int count;
  final bool compact;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = parseTileColor(option.color) ??
        theme.colorScheme.secondaryContainer;
    final foreground = background.computeLuminance() > 0.5
        ? Colors.black87
        : Colors.white;

    Widget tile = SizedBox(
      width: width,
      height: height,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(compact ? 6 : 10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // One line, shrunk to fit narrow tiles ("Bust", "+10").
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          option.displayText,
                          maxLines: 1,
                          softWrap: false,
                          style: TextStyle(
                            color: foreground,
                            fontSize: compact ? 15 : 22,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                    if (!compact && option.label != null)
                      Text(
                        option.label!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: foreground, fontSize: 11),
                      ),
                  ],
                ),
              ),
              if (count > 0)
                Positioned(
                  top: 3,
                  right: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '×$count',
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (tooltip != null) {
      tile = Tooltip(message: tooltip, child: tile);
    }
    return tile;
  }
}

/// Reads a `#RRGGBB` colour, or null if there is none.
Color? parseTileColor(String? hex) {
  if (hex == null || hex.length != 7) {
    return null;
  }
  final value = int.tryParse(hex.substring(1), radix: 16);
  return value == null ? null : Color(0xFF000000 | value);
}
