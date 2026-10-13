import 'package:flutter/material.dart';
import 'package:scoard_game/application/models/sessions/player_color.dart';

extension PlayerColorSwatch on PlayerColor {
  Color get swatch => switch (this) {
        PlayerColor.red => const Color(0xFFE53935),
        PlayerColor.orange => const Color(0xFFFB8C00),
        PlayerColor.yellow => const Color(0xFFFDD835),
        PlayerColor.green => const Color(0xFF43A047),
        PlayerColor.blue => const Color(0xFF1E88E5),
        PlayerColor.purple => const Color(0xFF8E24AA),
        PlayerColor.pink => const Color(0xFFEC407A),
        PlayerColor.brown => const Color(0xFF795548),
        PlayerColor.black => const Color(0xFF1A1A1A),
        PlayerColor.white => const Color(0xFFFFFFFF),
      };

  /// Black and white disappear against one of the themes, so they also get
  /// a thin neutral outline.
  bool get needsOutline =>
      this == PlayerColor.black || this == PlayerColor.white;
}

/// A player's card, with a coloured border and soft glow when the player
/// has a colour for this game. The card's contents are left alone.
class PlayerHaloCard extends StatelessWidget {
  const PlayerHaloCard({
    required this.color,
    required this.child,
    this.margin = EdgeInsets.zero,
    this.compact = false,
    super.key,
  });

  final PlayerColor? color;
  final Widget child;
  final EdgeInsetsGeometry margin;

  /// Tighter glow so it does not spill onto rows packed close together.
  final bool compact;

  static const double _radius = 12;

  @override
  Widget build(BuildContext context) {
    final color = this.color;
    if (color == null) {
      return Card(margin: margin, clipBehavior: Clip.antiAlias, child: child);
    }

    final theme = Theme.of(context);
    final swatch = color.swatch;
    final outline = color.needsOutline ? theme.colorScheme.outline : null;

    return Padding(
      padding: margin,
      child: Container(
        padding: EdgeInsets.all(outline == null ? 0 : 1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius + (outline == null ? 0 : 1)),
          border: outline == null ? null : Border.all(color: outline),
          boxShadow: [
            BoxShadow(
              color: swatch.withValues(alpha: 0.45),
              blurRadius: compact ? 3 : 8,
              spreadRadius: compact ? 0 : 1,
            ),
          ],
        ),
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
            side: BorderSide(color: swatch, width: 2),
          ),
          child: child,
        ),
      ),
    );
  }
}
