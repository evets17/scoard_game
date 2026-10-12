import 'package:flutter/material.dart';
import 'package:scoard_game/application/models/players/player_group.dart';
import 'package:scoard_game/application/models/players/player_list_item_model.dart';
import 'package:scoard_game/application/models/players/players_screen_model.dart';
import 'package:scoard_game/application/services/players/archive_player.dart';
import 'package:scoard_game/application/services/players/create_player.dart';
import 'package:scoard_game/application/services/players/create_player_group.dart';
import 'package:scoard_game/application/services/players/delete_player_group.dart';
import 'package:scoard_game/application/services/players/load_players_screen_model.dart';
import 'package:scoard_game/application/services/players/rename_player.dart';
import 'package:scoard_game/application/services/players/rename_player_group.dart';
import 'package:scoard_game/application/services/players/set_player_groups.dart';
import 'package:scoard_game/application/services/players/unarchive_player.dart';
import 'package:scoard_game/ui/navigation/app_screen_scaffold.dart';
import 'package:scoard_game/ui/players/group_name_dialog.dart';
import 'package:scoard_game/ui/players/player_editor_sheet.dart';
import 'package:scoard_game/ui/players/player_list_item.dart';
import 'package:scoard_game/ui/players/players_empty_state.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({
    required this.loadPlayersScreenModel,
    required this.createPlayer,
    required this.renamePlayer,
    required this.archivePlayer,
    required this.unarchivePlayer,
    required this.createPlayerGroup,
    required this.renamePlayerGroup,
    required this.deletePlayerGroup,
    required this.setPlayerGroups,
    super.key,
  });

  final LoadPlayersScreenModel loadPlayersScreenModel;
  final CreatePlayer createPlayer;
  final RenamePlayer renamePlayer;
  final ArchivePlayer archivePlayer;
  final UnarchivePlayer unarchivePlayer;
  final CreatePlayerGroup createPlayerGroup;
  final RenamePlayerGroup renamePlayerGroup;
  final DeletePlayerGroup deletePlayerGroup;
  final SetPlayerGroups setPlayerGroups;

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

/// Which players the list shows: everyone active, one group, or archived.
sealed class _PlayersFilter {
  const _PlayersFilter();
}

class _AllPlayers extends _PlayersFilter {
  const _AllPlayers();
}

class _ArchivedPlayers extends _PlayersFilter {
  const _ArchivedPlayers();
}

class _GroupPlayers extends _PlayersFilter {
  const _GroupPlayers(this.groupId);

  final String groupId;
}

class _PlayersScreenState extends State<PlayersScreen> {
  late Future<PlayersScreenModel> _playersModelFuture;
  _PlayersFilter _filter = const _AllPlayers();

  @override
  void initState() {
    super.initState();
    _playersModelFuture = widget.loadPlayersScreenModel();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScreenScaffold(
      title: 'Players',
      child: FutureBuilder<PlayersScreenModel>(
        future: _playersModelFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Players could not load right now.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            );
          }

          // Keep showing the previous model while changes reload it.
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          final model = snapshot.requireData;
          final filter = _resolveFilter(model);
          final groupNamesById = {
            for (final group in model.groups) group.id: group.name,
          };

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FilledButton.icon(
                onPressed: () => _handleAddPlayer(model),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Player'),
              ),
              const SizedBox(height: 16),
              _FilterChipRow(
                groups: model.groups,
                filter: filter,
                onSelected: (filter) => setState(() => _filter = filter),
                onManageGroups: () => _handleManageGroups(model),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _buildPlayerList(
                  model,
                  filter: filter,
                  groupNamesById: groupNamesById,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlayerList(
    PlayersScreenModel model, {
    required _PlayersFilter filter,
    required Map<String, String> groupNamesById,
  }) {
    final players = switch (filter) {
      _AllPlayers() => model.activePlayers,
      _ArchivedPlayers() => model.archivedPlayers,
      _GroupPlayers(:final groupId) => model.activePlayers
          .where((player) => player.groupIds.contains(groupId))
          .toList(growable: false),
    };

    if (players.isEmpty) {
      return ListView(
        children: [
          switch (filter) {
            _AllPlayers() => PlayersEmptyState(
                title: 'No players yet',
                message:
                    'Add your first player so Scoard Game is ready for the next table.',
                actionLabel: 'Add Player',
                onAction: () => _handleAddPlayer(model),
              ),
            _ArchivedPlayers() => const PlayersEmptyState(
                title: 'No archived players',
                message:
                    'Archived players will appear here when you hide them from the active list.',
              ),
            _GroupPlayers(:final groupId) => PlayersEmptyState(
                title: 'No one in ${groupNamesById[groupId]} yet',
                message:
                    'Tap a player to add them to this group, or add a new player while it is selected.',
              ),
          },
        ],
      );
    }

    return ListView(
      children: players
          .map(
            (player) => PlayerListItem(
              player: player,
              groupNames: model.groups
                  .where((group) => player.groupIds.contains(group.id))
                  .map((group) => group.name)
                  .toList(growable: false),
              onTap: () => _handleEditPlayer(model, player),
            ),
          )
          .toList(growable: false),
    );
  }

  /// Falls back to All when the selected group no longer exists.
  _PlayersFilter _resolveFilter(PlayersScreenModel model) {
    final filter = _filter;
    if (filter is _GroupPlayers &&
        !model.groups.any((group) => group.id == filter.groupId)) {
      return const _AllPlayers();
    }

    return filter;
  }

  Future<void> _handleAddPlayer(PlayersScreenModel model) async {
    final filter = _resolveFilter(model);
    final result = await showPlayerDetailsSheet(
      context,
      title: 'Add Player',
      confirmLabel: 'Save Player',
      existingPlayers: _allPlayers(model),
      groups: model.groups,
      // A player added while a group is selected starts in that group.
      initialGroupIds: {
        if (filter is _GroupPlayers) filter.groupId,
      },
      onCreateGroup: _createGroup,
    );

    if (result == null || result.name == null) {
      _reload();
      return;
    }

    await _runMutation(() async {
      final player = await widget.createPlayer(displayName: result.name!);
      if (result.groupIds.isNotEmpty) {
        await widget.setPlayerGroups(
          playerId: player.id,
          groupIds: result.groupIds,
        );
      }
    });
  }

  Future<void> _handleEditPlayer(
    PlayersScreenModel model,
    PlayerListItemModel player,
  ) async {
    final result = await showPlayerDetailsSheet(
      context,
      title: 'Edit Player',
      confirmLabel: 'Save Changes',
      initialValue: player.displayName,
      initialGroupIds: player.groupIds,
      existingPlayers: _allPlayers(model),
      editingPlayerId: player.id,
      groups: model.groups,
      onCreateGroup: _createGroup,
      statusAction: player.isArchived
          ? PlayerEditorAction.restore
          : PlayerEditorAction.archive,
    );

    if (result == null) {
      // Groups made in the sheet are kept even if the edit is cancelled.
      _reload();
      return;
    }

    switch (result.action) {
      case PlayerEditorAction.save:
        await _runMutation(() async {
          if (result.name != player.displayName) {
            await widget.renamePlayer(
              playerId: player.id,
              displayName: result.name!,
            );
          }
          await widget.setPlayerGroups(
            playerId: player.id,
            groupIds: result.groupIds,
          );
        });
      case PlayerEditorAction.archive:
        await _handleArchivePlayer(player);
      case PlayerEditorAction.restore:
        await _runMutation(
          () => widget.unarchivePlayer(playerId: player.id),
        );
    }
  }

  Future<void> _handleArchivePlayer(PlayerListItemModel player) async {
    final shouldArchive = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Player'),
        content: Text(
          'Hide ${player.displayName} from the active players list? Their games and groups are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (shouldArchive != true) {
      return;
    }

    await _runMutation(() => widget.archivePlayer(playerId: player.id));
  }

  Future<void> _handleManageGroups(PlayersScreenModel model) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ManageGroupsSheet(
        initialGroups: model.groups,
        onCreate: _createGroup,
        onRename: (group, name) =>
            widget.renamePlayerGroup(groupId: group.id, name: name),
        onDelete: (group) => widget.deletePlayerGroup(groupId: group.id),
      ),
    );

    _reload();
  }

  Future<PlayerGroup> _createGroup(String name) {
    return widget.createPlayerGroup(name: name);
  }

  void _reload() {
    if (!mounted) {
      return;
    }

    setState(() {
      _playersModelFuture = widget.loadPlayersScreenModel();
    });
  }

  Future<void> _runMutation(Future<void> Function() operation) async {
    try {
      await operation();
    } on PlayerValidationException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }

    _reload();
  }

  List<PlayerListItemModel> _allPlayers(PlayersScreenModel model) {
    return [
      ...model.activePlayers,
      ...model.archivedPlayers,
    ];
  }
}

class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow({
    required this.groups,
    required this.filter,
    required this.onSelected,
    required this.onManageGroups,
  });

  final List<PlayerGroup> groups;
  final _PlayersFilter filter;
  final ValueChanged<_PlayersFilter> onSelected;
  final VoidCallback onManageGroups;

  @override
  Widget build(BuildContext context) {
    final selectedGroupId = switch (filter) {
      _GroupPlayers(:final groupId) => groupId,
      _ => null,
    };

    Widget chip(String label, bool selected, _PlayersFilter value) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onSelected(value),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                chip('All', filter is _AllPlayers, const _AllPlayers()),
                ...groups.map(
                  (group) => chip(
                    group.name,
                    group.id == selectedGroupId,
                    _GroupPlayers(group.id),
                  ),
                ),
                chip(
                  'Archived',
                  filter is _ArchivedPlayers,
                  const _ArchivedPlayers(),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          onPressed: onManageGroups,
          icon: const Icon(Icons.edit_note_rounded),
          tooltip: 'Manage groups',
        ),
      ],
    );
  }
}

class _ManageGroupsSheet extends StatefulWidget {
  const _ManageGroupsSheet({
    required this.initialGroups,
    required this.onCreate,
    required this.onRename,
    required this.onDelete,
  });

  final List<PlayerGroup> initialGroups;
  final Future<PlayerGroup> Function(String name) onCreate;
  final Future<PlayerGroup> Function(PlayerGroup group, String name) onRename;
  final Future<void> Function(PlayerGroup group) onDelete;

  @override
  State<_ManageGroupsSheet> createState() => _ManageGroupsSheetState();
}

class _ManageGroupsSheetState extends State<_ManageGroupsSheet> {
  late final List<PlayerGroup> _groups = [...widget.initialGroups];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Groups', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Deleting a group keeps its players.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (_groups.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No groups yet.',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  ..._groups.map(
                    (group) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(group.name),
                      onTap: () => _rename(group),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _rename(group),
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Rename ${group.name}',
                          ),
                          IconButton(
                            onPressed: () => _delete(group),
                            icon: const Icon(Icons.delete_outline_rounded),
                            tooltip: 'Delete ${group.name}',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: _create,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('New Group'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _create() async {
    final group = await showGroupNameDialog<PlayerGroup>(
      context,
      title: 'New Group',
      confirmLabel: 'Create',
      onSubmit: widget.onCreate,
    );

    if (group != null && mounted) {
      setState(() => _groups.add(group));
    }
  }

  Future<void> _rename(PlayerGroup group) async {
    final renamed = await showGroupNameDialog<PlayerGroup>(
      context,
      title: 'Rename Group',
      confirmLabel: 'Save',
      initialValue: group.name,
      onSubmit: (name) => widget.onRename(group, name),
    );

    if (renamed != null && mounted) {
      setState(() {
        final index = _groups.indexWhere((existing) => existing.id == group.id);
        _groups[index] = renamed;
      });
    }
  }

  Future<void> _delete(PlayerGroup group) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text(
          'Delete "${group.name}"? Its players stay; they are just removed from this group.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    await widget.onDelete(group);
    if (mounted) {
      setState(() => _groups.removeWhere((existing) => existing.id == group.id));
    }
  }
}
