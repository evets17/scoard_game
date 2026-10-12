import 'package:scoard_game/application/models/players/player_group.dart';
import 'package:scoard_game/application/models/players/player_group_rules.dart';
import 'package:scoard_game/application/models/players/player_id_rules.dart';
import 'package:scoard_game/application/models/players/player_record.dart';
import 'package:scoard_game/application/repositories/player_repository.dart';

class MemoryPlayerRepository implements PlayerRepository {
  MemoryPlayerRepository._(this._players) : _groups = [];

  factory MemoryPlayerRepository.seeded() {
    final now = DateTime.now();

    return MemoryPlayerRepository._([
      PlayerRecord(
        id: 'player-avery',
        displayName: 'Avery',
        isArchived: false,
        createdAt: now.subtract(const Duration(days: 20)),
      ),
      PlayerRecord(
        id: 'player-jules',
        displayName: 'Jules',
        isArchived: false,
        createdAt: now.subtract(const Duration(days: 18)),
      ),
      PlayerRecord(
        id: 'player-mina',
        displayName: 'Mina',
        isArchived: false,
        createdAt: now.subtract(const Duration(days: 16)),
      ),
      PlayerRecord(
        id: 'player-owen',
        displayName: 'Owen',
        isArchived: false,
        createdAt: now.subtract(const Duration(days: 12)),
      ),
      PlayerRecord(
        id: 'player-rio',
        displayName: 'Rio',
        isArchived: false,
        createdAt: now.subtract(const Duration(days: 8)),
      ),
    ]);
  }

  final List<PlayerRecord> _players;
  final List<PlayerGroup> _groups;

  @override
  Future<List<PlayerRecord>> loadPlayers() async {
    return _players.toList(growable: false);
  }

  @override
  Future<PlayerRecord> createPlayer({required String displayName}) async {
    final createdAt = DateTime.now();
    final player = PlayerRecord(
      id: createPlayerId(displayName, timestamp: createdAt),
      displayName: displayName,
      isArchived: false,
      createdAt: createdAt,
    );

    _players.add(player);

    return player;
  }

  @override
  Future<PlayerRecord> renamePlayer({
    required String playerId,
    required String displayName,
  }) async {
    final playerIndex = _players.indexWhere((player) => player.id == playerId);
    final existingPlayer = _getPlayerAt(playerIndex, playerId);
    final updatedPlayer = existingPlayer.copyWith(displayName: displayName);

    _players[playerIndex] = updatedPlayer;

    return updatedPlayer;
  }

  @override
  Future<PlayerRecord> setArchived({
    required String playerId,
    required bool isArchived,
  }) async {
    final playerIndex = _players.indexWhere((player) => player.id == playerId);
    final existingPlayer = _getPlayerAt(playerIndex, playerId);
    final updatedPlayer = existingPlayer.copyWith(isArchived: isArchived);

    _players[playerIndex] = updatedPlayer;

    return updatedPlayer;
  }

  @override
  Future<List<PlayerGroup>> loadGroups() async {
    return _groups.toList(growable: false);
  }

  @override
  Future<PlayerGroup> createGroup({required String name}) async {
    final createdAt = DateTime.now();
    final group = PlayerGroup(
      id: createPlayerGroupId(name, timestamp: createdAt),
      name: name,
      createdAt: createdAt,
    );

    _groups.add(group);

    return group;
  }

  @override
  Future<PlayerGroup> renameGroup({
    required String groupId,
    required String name,
  }) async {
    final groupIndex = _groups.indexWhere((group) => group.id == groupId);
    if (groupIndex == -1) {
      throw StateError('Group not found: $groupId');
    }

    final existingGroup = _groups[groupIndex];
    final updatedGroup = PlayerGroup(
      id: existingGroup.id,
      name: name,
      createdAt: existingGroup.createdAt,
    );
    _groups[groupIndex] = updatedGroup;

    return updatedGroup;
  }

  @override
  Future<void> deleteGroup({required String groupId}) async {
    _groups.removeWhere((group) => group.id == groupId);

    for (var index = 0; index < _players.length; index++) {
      final player = _players[index];
      if (player.groupIds.contains(groupId)) {
        _players[index] = player.copyWith(
          groupIds: {...player.groupIds}..remove(groupId),
        );
      }
    }
  }

  @override
  Future<PlayerRecord> setPlayerGroups({
    required String playerId,
    required Set<String> groupIds,
  }) async {
    final playerIndex = _players.indexWhere((player) => player.id == playerId);
    final existingPlayer = _getPlayerAt(playerIndex, playerId);
    final updatedPlayer = existingPlayer.copyWith(groupIds: {...groupIds});

    _players[playerIndex] = updatedPlayer;

    return updatedPlayer;
  }

  PlayerRecord _getPlayerAt(int playerIndex, String playerId) {
    if (playerIndex == -1) {
      throw StateError('Player not found: $playerId');
    }

    return _players[playerIndex];
  }
}