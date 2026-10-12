import 'package:scoard_game/application/models/players/player_group.dart';
import 'package:scoard_game/application/models/players/player_group_rules.dart';
import 'package:scoard_game/application/repositories/player_repository.dart';

class CreatePlayerGroup {
  const CreatePlayerGroup({required this.playerRepository});

  final PlayerRepository playerRepository;

  Future<PlayerGroup> call({required String name}) async {
    final validatedName = validatePlayerGroupName(
      name: name,
      existingGroups: await playerRepository.loadGroups(),
    );

    return playerRepository.createGroup(name: validatedName);
  }
}
