import 'package:flutter/material.dart';
import 'package:scoard_game/application/models/sessions/player_sort_mode.dart';

class PlayerSortMenuButton extends StatelessWidget {
  const PlayerSortMenuButton({
    required this.sortMode,
    required this.onSelected,
    super.key,
  });

  final PlayerSortMode sortMode;
  final ValueChanged<PlayerSortMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<PlayerSortMode>(
      icon: const Icon(Icons.sort_rounded),
      tooltip: 'Sort players',
      initialValue: sortMode,
      onSelected: onSelected,
      itemBuilder: (context) => PlayerSortMode.values
          .map(
            (mode) => CheckedPopupMenuItem<PlayerSortMode>(
              value: mode,
              checked: mode == sortMode,
              child: Text(playerSortModeLabel(mode)),
            ),
          )
          .toList(growable: false),
    );
  }
}

String playerSortModeLabel(PlayerSortMode mode) {
  return switch (mode) {
    PlayerSortMode.playOrder => 'Play order',
    PlayerSortMode.name => 'Name',
    PlayerSortMode.score => 'Score',
  };
}
