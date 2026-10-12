import 'package:flutter/material.dart';
import 'package:scoard_game/application/models/players/player_group.dart';

/// A scrolling row of All plus one chip per group. A null id means All.
class PlayerGroupFilterChips extends StatelessWidget {
  const PlayerGroupFilterChips({
    required this.groups,
    required this.selectedGroupId,
    required this.onSelected,
    super.key,
  });

  final List<PlayerGroup> groups;
  final String? selectedGroupId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, String? groupId) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selectedGroupId == groupId,
          onSelected: (_) => onSelected(groupId),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip('All', null),
          ...groups.map((group) => chip(group.name, group.id)),
        ],
      ),
    );
  }
}
