import 'package:scoard_game/application/models/players/player_list_item_model.dart';
import 'package:scoard_game/application/models/players/player_record.dart';
import 'package:scoard_game/application/models/players/players_screen_model.dart';
import 'package:scoard_game/application/repositories/player_repository.dart';

class LoadPlayersScreenModel {
  const LoadPlayersScreenModel({required this.playerRepository});

  final PlayerRepository playerRepository;

  Future<PlayersScreenModel> call() async {
    final players = await playerRepository.loadPlayers();
    final groups = (await playerRepository.loadGroups()).toList(growable: false)
      ..sort(
        (left, right) =>
            left.name.toLowerCase().compareTo(right.name.toLowerCase()),
      );

    final sortedPlayers = players.toList(growable: false)
      ..sort((left, right) => left.createdAt.compareTo(right.createdAt));

    PlayerListItemModel toListItem(PlayerRecord player) => PlayerListItemModel(
          id: player.id,
          displayName: player.displayName,
          isArchived: player.isArchived,
          groupIds: player.groupIds,
        );

    return PlayersScreenModel(
      activePlayers: sortedPlayers
          .where((player) => !player.isArchived)
          .map(toListItem)
          .toList(growable: false),
      archivedPlayers: sortedPlayers
          .where((player) => player.isArchived)
          .map(toListItem)
          .toList(growable: false),
      groups: groups,
    );
  }
}
