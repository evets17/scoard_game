import 'package:scoard_game/application/models/players/player_record.dart';
import 'package:scoard_game/application/repositories/player_repository.dart';

class SetPlayerGroups {
  const SetPlayerGroups({required this.playerRepository});

  final PlayerRepository playerRepository;

  Future<PlayerRecord> call({
    required String playerId,
    required Set<String> groupIds,
  }) async {
    final knownGroupIds =
        (await playerRepository.loadGroups()).map((group) => group.id).toSet();

    return playerRepository.setPlayerGroups(
      playerId: playerId,
      groupIds: groupIds.intersection(knownGroupIds),
    );
  }
}
