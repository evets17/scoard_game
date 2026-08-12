import 'package:scoard_game/application/models/players/player_record.dart';
import 'package:scoard_game/application/repositories/player_repository.dart';

class ArchivePlayer {
  const ArchivePlayer({required this.playerRepository});

  final PlayerRepository playerRepository;

  Future<PlayerRecord> call({required String playerId}) {
    return playerRepository.setArchived(playerId: playerId, isArchived: true);
  }
}