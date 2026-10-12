import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/infrastructure/persistence/db/app_database.dart';
import 'package:scoard_game/infrastructure/persistence/repositories/persistent_player_repository.dart';

void main() {
  test('stores groups and memberships, and archiving keeps them', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final repository = PersistentPlayerRepository(database);

    final avery = await repository.createPlayer(displayName: 'Avery');
    final family = await repository.createGroup(name: 'Family');
    final friends = await repository.createGroup(name: 'Friends');

    await repository.setPlayerGroups(
      playerId: avery.id,
      groupIds: {family.id, friends.id},
    );
    await repository.setArchived(playerId: avery.id, isArchived: true);

    final stored = (await repository.loadPlayers()).single;
    expect(stored.isArchived, isTrue);
    expect(stored.groupIds, {family.id, friends.id});

    await repository.renameGroup(groupId: family.id, name: 'Household');
    expect(
      (await repository.loadGroups()).map((group) => group.name),
      containsAll(['Household', 'Friends']),
    );

    await database.close();
  });

  test('deleting a group removes memberships but keeps players', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final repository = PersistentPlayerRepository(database);

    final avery = await repository.createPlayer(displayName: 'Avery');
    final family = await repository.createGroup(name: 'Family');
    await repository.setPlayerGroups(playerId: avery.id, groupIds: {family.id});

    await repository.deleteGroup(groupId: family.id);

    expect(await repository.loadGroups(), isEmpty);
    final stored = (await repository.loadPlayers()).single;
    expect(stored.displayName, 'Avery');
    expect(stored.groupIds, isEmpty);

    await database.close();
  });

  test('upgrading a version 6 database adds the group tables', () async {
    final directory = await Directory.systemTemp.createTemp('scoard_groups');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/app.sqlite');

    // Build a database, then roll it back to how version 6 looked.
    final original = AppDatabase.forTesting(NativeDatabase(file));
    await PersistentPlayerRepository(original)
        .createPlayer(displayName: 'Avery');
    await original.customStatement('DROP TABLE player_groups_table');
    await original.customStatement('DROP TABLE player_group_members_table');
    await original.customStatement('PRAGMA user_version = 6');
    await original.close();

    final upgraded = AppDatabase.forTesting(NativeDatabase(file));
    final repository = PersistentPlayerRepository(upgraded);

    final family = await repository.createGroup(name: 'Family');
    final avery = (await repository.loadPlayers()).single;
    await repository.setPlayerGroups(playerId: avery.id, groupIds: {family.id});

    expect((await repository.loadPlayers()).single.groupIds, {family.id});

    await upgraded.close();
  });
}
