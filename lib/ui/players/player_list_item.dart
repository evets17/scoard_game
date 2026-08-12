import 'package:flutter/material.dart';
import 'package:scoard_game/application/models/players/player_list_item_model.dart';

class PlayerListItem extends StatelessWidget {
  const PlayerListItem({
    required this.player,
    required this.onTap,
    required this.onArchiveToggle,
    super.key,
  });

  final PlayerListItemModel player;
  final VoidCallback onTap;
  final VoidCallback onArchiveToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  player.displayName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 22,
                  ),
                ),
              ),
              IconButton(
                onPressed: onArchiveToggle,
                constraints: const BoxConstraints.tightFor(
                  width: 40,
                  height: 40,
                ),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  player.isArchived
                      ? Icons.unarchive_rounded
                      : Icons.archive_outlined,
                ),
                tooltip: player.isArchived ? 'Restore player' : 'Archive player',
              ),
            ],
          ),
        ),
      ),
    );
  }
}