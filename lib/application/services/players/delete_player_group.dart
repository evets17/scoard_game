import 'package:scoard_game/application/repositories/player_repository.dart';

class DeletePlayerGroup {
  const DeletePlayerGroup({required this.playerRepository});

  final PlayerRepository playerRepository;

  Future<void> call({required String groupId}) {
    return playerRepository.deleteGroup(groupId: groupId);
  }
}
