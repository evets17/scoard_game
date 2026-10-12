import 'package:flutter/material.dart';
import 'package:scoard_game/application/models/scoring/value_picker_definition.dart';

/// Tap the values in front of a player (such as Skyjo cards) to add them up.
///
/// [picked] holds the tapped values in order. The picked values sit above
/// the tiles, so the tiles stay put as the list grows.
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
  final ValueChanged<int> onAdd;
  final ValueChanged<int> onRemoveAt;

  static const double _gap = 6;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final optionsByValue = {
      for (final option in definition.options) option.value: option,
    };
    final total = picked.fold<int>(0, (sum, value) => sum + value);

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
          constraints: const BoxConstraints(minHeight: 44),
          child: picked.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
                    for (var index = 0; index < picked.length; index++)
                      _ValueTile(
                        option: optionsByValue[picked[index]] ??
                            ValuePickerOption(value: picked[index]),
                        width: 36,
                        height: 44,
                        compact: true,
                        tooltip: 'Remove ${picked[index]}',
                        onTap: () => onRemoveAt(index),
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

            return Wrap(
              spacing: _gap,
              runSpacing: _gap,
              children: [
                for (final option in definition.options)
                  _ValueTile(
                    option: option,
                    width: tileWidth,
                    height: option.label == null ? 52 : 60,
                    count: picked.where((value) => value == option.value).length,
                    onTap: () => onAdd(option.value),
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
                    Text(
                      '${option.value}',
                      style: TextStyle(
                        color: foreground,
                        fontSize: compact ? 16 : 22,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
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
