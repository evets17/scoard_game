import 'package:scoard_game/application/models/players/player_group.dart';
import 'package:scoard_game/application/models/players/player_record.dart';

abstract class PlayerRepository {
  Future<List<PlayerRecord>> loadPlayers();

  Future<PlayerRecord> createPlayer({required String displayName});

  Future<PlayerRecord> renamePlayer({
    required String playerId,
    required String displayName,
  });

  Future<PlayerRecord> setArchived({
    required String playerId,
    required bool isArchived,
  });

  Future<List<PlayerGroup>> loadGroups();

  Future<PlayerGroup> createGroup({required String name});

  Future<PlayerGroup> renameGroup({
    required String groupId,
    required String name,
  });

  /// Deletes the group and its memberships. Players are not affected.
  Future<void> deleteGroup({required String groupId});

  Future<PlayerRecord> setPlayerGroups({
    required String playerId,
    required Set<String> groupIds,
  });
}
