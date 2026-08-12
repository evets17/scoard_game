import 'package:scoard_game/application/models/players/player_id_rules.dart';
import 'package:scoard_game/application/models/players/player_record.dart';
import 'package:scoard_game/application/repositories/player_repository.dart';
import 'package:scoard_game/infrastructure/persistence/db/app_database.dart';

class PersistentPlayerRepository implements PlayerRepository {
  PersistentPlayerRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  @override
  Future<List<PlayerRecord>> loadPlayers() {
    return _appDatabase.loadPlayers();
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

    await _appDatabase.createPlayer(
      id: player.id,
      displayName: player.displayName,
      createdAt: player.createdAt,
    );

    return player;
  }

  @override
  Future<PlayerRecord> renamePlayer({
    required String playerId,
    required String displayName,
  }) async {
    final existingPlayer = await _requirePlayer(playerId);

    await _appDatabase.renamePlayer(id: playerId, displayName: displayName);

    return existingPlayer.copyWith(displayName: displayName);
  }

  @override
  Future<PlayerRecord> setArchived({
    required String playerId,
    required bool isArchived,
  }) async {
    final existingPlayer = await _requirePlayer(playerId);

    await _appDatabase.setPlayerArchived(id: playerId, isArchived: isArchived);

    return existingPlayer.copyWith(isArchived: isArchived);
  }

  Future<PlayerRecord> _requirePlayer(String playerId) async {
    final players = await loadPlayers();

    return players.firstWhere(
      (player) => player.id == playerId,
      orElse: () => throw StateError('Player not found: $playerId'),
    );
  }
}