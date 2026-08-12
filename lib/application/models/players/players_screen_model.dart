import 'package:scoard_game/application/models/players/player_list_item_model.dart';

class PlayersScreenModel {
  const PlayersScreenModel({
    required this.activePlayers,
    required this.archivedPlayers,
  });

  final List<PlayerListItemModel> activePlayers;
  final List<PlayerListItemModel> archivedPlayers;

  bool get hasActivePlayers => activePlayers.isNotEmpty;

  bool get hasArchivedPlayers => archivedPlayers.isNotEmpty;
}