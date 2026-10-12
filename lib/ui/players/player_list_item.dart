import 'package:flutter/material.dart';
import 'package:scoard_game/application/models/players/player_list_item_model.dart';

class PlayerListItem extends StatelessWidget {
  const PlayerListItem({
    required this.player,
    required this.onTap,
    this.groupNames = const [],
    super.key,
  });

  final PlayerListItemModel player;
  final VoidCallback onTap;

  /// Names of the groups the player belongs to, shown under their name.
  final List<String> groupNames;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 22,
                      ),
                    ),
                    if (groupNames.isNotEmpty)
                      Text(
                        groupNames.join(' · '),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
