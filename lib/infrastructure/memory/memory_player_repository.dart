import 'package:scoard_game/application/models/players/player_id_rules.dart';
import 'package:scoard_game/application/models/players/player_record.dart';
import 'package:scoard_game/application/repositories/player_repository.dart';

class MemoryPlayerRepository implements PlayerRepository {
  MemoryPlayerRepository._(this._players);

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

  PlayerRecord _getPlayerAt(int playerIndex, String playerId) {
    if (playerIndex == -1) {
      throw StateError('Player not found: $playerId');
    }

    return _players[playerIndex];
  }
}