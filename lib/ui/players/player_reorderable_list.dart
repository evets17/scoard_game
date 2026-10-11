import 'package:flutter/material.dart';

/// A list whose rows can be dragged into a new order after a long press.
class PlayerReorderableList extends StatelessWidget {
  const PlayerReorderableList({
    required this.playerIds,
    required this.itemBuilder,
    required this.onReorder,
    this.canReorder = true,
    this.shrinkWrap = false,
    super.key,
  });

  final List<String> playerIds;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final ReorderCallback onReorder;
  final bool canReorder;

  /// Set when nested inside another scrolling list.
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      itemCount: playerIds.length,
      onReorder: onReorder,
      itemBuilder: (context, index) => ReorderableDelayedDragStartListener(
        key: ValueKey(playerIds[index]),
        index: index,
        enabled: canReorder,
        child: itemBuilder(context, index),
      ),
    );
  }
}
