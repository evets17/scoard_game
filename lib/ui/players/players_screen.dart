import 'package:flutter/material.dart';
import 'package:scoard_game/application/models/players/player_list_item_model.dart';
import 'package:scoard_game/application/models/players/players_screen_model.dart';
import 'package:scoard_game/application/services/players/archive_player.dart';
import 'package:scoard_game/application/services/players/create_player.dart';
import 'package:scoard_game/application/services/players/load_players_screen_model.dart';
import 'package:scoard_game/application/services/players/rename_player.dart';
import 'package:scoard_game/application/services/players/unarchive_player.dart';
import 'package:scoard_game/ui/navigation/app_screen_scaffold.dart';
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
    super.key,
  });

  final LoadPlayersScreenModel loadPlayersScreenModel;
  final CreatePlayer createPlayer;
  final RenamePlayer renamePlayer;
  final ArchivePlayer archivePlayer;
  final UnarchivePlayer unarchivePlayer;

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  late Future<PlayersScreenModel> _playersModelFuture;
  bool _showArchived = false;

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
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Players could not load right now.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            );
          }

          final model = snapshot.requireData;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: _handleAddPlayer,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Player'),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _showArchived = !_showArchived);
                    },
                    icon: Icon(
                      _showArchived
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                    ),
                    label: Text(_showArchived ? 'Hide Archived' : 'View Archived'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    if (!model.hasActivePlayers)
                      PlayersEmptyState(
                        title: 'No players yet',
                        message:
                            'Add your first player so Scoard Game is ready for the next table.',
                        actionLabel: 'Add Player',
                        onAction: _handleAddPlayer,
                      )
                    else
                      ...model.activePlayers.map(
                        (player) => PlayerListItem(
                          player: player,
                          onTap: () => _handleEditPlayer(player),
                          onArchiveToggle: () => _handleArchivePlayer(player),
                        ),
                      ),
                    if (_showArchived) ...[
                      const SizedBox(height: 16),
                      Text('Archived', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 12),
                      if (!model.hasArchivedPlayers)
                        const PlayersEmptyState(
                          title: 'No archived players',
                          message:
                              'Archived players will appear here when you hide them from the active list.',
                        )
                      else
                        ...model.archivedPlayers.map(
                          (player) => PlayerListItem(
                            player: player,
                            onTap: () => _handleEditPlayer(player),
                            onArchiveToggle: () => _handleUnarchivePlayer(player),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleAddPlayer() async {
    final playersModel = await _playersModelFuture;

    if (!mounted) {
      return;
    }

    final playerName = await showPlayerEditorSheet(
      context,
      title: 'Add Player',
      confirmLabel: 'Save Player',
      existingPlayers: _allPlayers(playersModel),
    );

    if (playerName == null) {
      return;
    }

    await _runMutation(() => widget.createPlayer(displayName: playerName));
  }

  Future<void> _handleEditPlayer(PlayerListItemModel player) async {
    final playersModel = await _playersModelFuture;

    if (!mounted) {
      return;
    }

    final updatedName = await showPlayerEditorSheet(
      context,
      title: 'Edit Player',
      confirmLabel: 'Save Changes',
      initialValue: player.displayName,
      existingPlayers: _allPlayers(playersModel),
      editingPlayerId: player.id,
    );

    if (updatedName == null) {
      return;
    }

    await _runMutation(
      () => widget.renamePlayer(
        playerId: player.id,
        displayName: updatedName,
      ),
    );
  }

  Future<void> _handleArchivePlayer(PlayerListItemModel player) async {
    final shouldArchive = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Player'),
        content: Text('Hide ${player.displayName} from the active players list?'),
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

  Future<void> _handleUnarchivePlayer(PlayerListItemModel player) async {
    await _runMutation(() => widget.unarchivePlayer(playerId: player.id));
  }

  Future<void> _runMutation(Future<Object?> Function() operation) async {
    try {
      await operation();
      setState(() {
        _playersModelFuture = widget.loadPlayersScreenModel();
      });
    } on PlayerValidationException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  List<PlayerListItemModel> _allPlayers(PlayersScreenModel model) {
    return [
      ...model.activePlayers,
      ...model.archivedPlayers,
    ];
  }
}