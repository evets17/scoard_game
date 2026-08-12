import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/infrastructure/persistence/db/app_database.dart';
import 'package:scoard_game/infrastructure/persistence/repositories/persistent_player_repository.dart';

void main() {
  test('persistent player repository stores players across repository reloads', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final repository = PersistentPlayerRepository(database);

    final createdPlayer = await repository.createPlayer(displayName: 'Taylor');
    await repository.renamePlayer(
      playerId: createdPlayer.id,
      displayName: 'Taylor R.',
    );
    await repository.setArchived(playerId: createdPlayer.id, isArchived: true);

    final reloadedPlayers = await repository.loadPlayers();
    final persistedPlayer = reloadedPlayers.singleWhere(
      (player) => player.id == createdPlayer.id,
    );

    expect(persistedPlayer.displayName, 'Taylor R.');
    expect(persistedPlayer.isArchived, isTrue);

    await database.close();
  });
}