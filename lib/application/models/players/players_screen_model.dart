import 'package:scoard_game/application/models/players/player_group.dart';
import 'package:scoard_game/application/models/players/player_list_item_model.dart';

class PlayersScreenModel {
  const PlayersScreenModel({
    required this.activePlayers,
    required this.archivedPlayers,
    this.groups = const [],
  });

  final List<PlayerListItemModel> activePlayers;
  final List<PlayerListItemModel> archivedPlayers;

  /// User-made groups, sorted by name.
  final List<PlayerGroup> groups;

  bool get hasActivePlayers => activePlayers.isNotEmpty;

  bool get hasArchivedPlayers => archivedPlayers.isNotEmpty;
}
