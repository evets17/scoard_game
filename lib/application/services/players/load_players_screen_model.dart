import 'package:scoard_game/application/models/players/player_list_item_model.dart';
import 'package:scoard_game/application/models/players/players_screen_model.dart';
import 'package:scoard_game/application/repositories/player_repository.dart';

class LoadPlayersScreenModel {
  const LoadPlayersScreenModel({required this.playerRepository});

  final PlayerRepository playerRepository;

  Future<PlayersScreenModel> call() async {
    final players = await playerRepository.loadPlayers();

    final sortedPlayers = players.toList(growable: false)
      ..sort((left, right) => left.createdAt.compareTo(right.createdAt));

    final activePlayers = sortedPlayers
        .where((player) => !player.isArchived)
        .map(
          (player) => PlayerListItemModel(
            id: player.id,
            displayName: player.displayName,
            isArchived: player.isArchived,
          ),
        )
        .toList(growable: false);

    final archivedPlayers = sortedPlayers
        .where((player) => player.isArchived)
        .map(
          (player) => PlayerListItemModel(
            id: player.id,
            displayName: player.displayName,
            isArchived: player.isArchived,
          ),
        )
        .toList(growable: false);

    return PlayersScreenModel(
      activePlayers: activePlayers,
      archivedPlayers: archivedPlayers,
    );
  }
}