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
}