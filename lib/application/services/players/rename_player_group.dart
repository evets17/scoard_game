import 'package:scoard_game/application/models/players/player_group.dart';
import 'package:scoard_game/application/models/players/player_group_rules.dart';
import 'package:scoard_game/application/repositories/player_repository.dart';

class RenamePlayerGroup {
  const RenamePlayerGroup({required this.playerRepository});

  final PlayerRepository playerRepository;

  Future<PlayerGroup> call({
    required String groupId,
    required String name,
  }) async {
    final validatedName = validatePlayerGroupName(
      name: name,
      existingGroups: await playerRepository.loadGroups(),
      editingGroupId: groupId,
    );

    return playerRepository.renameGroup(groupId: groupId, name: validatedName);
  }
}
