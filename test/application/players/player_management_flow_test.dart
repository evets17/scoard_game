import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/bootstrap/app_bootstrap.dart';
import 'package:scoard_game/application/services/players/create_player.dart';

import '../../support/test_templates.dart';

void main() {
  test('player flow supports create, archive, and unarchive', () async {
    final environment = await AppBootstrap.initialize(
      templateCatalog: loadTestTemplateCatalog(),
    );

    final initialModel = await environment.loadPlayersScreenModel();
    expect(initialModel.activePlayers, isNotEmpty);

    final createdPlayer = await environment.createPlayer(displayName: 'Tess');

    final afterCreateModel = await environment.loadPlayersScreenModel();
    expect(
      afterCreateModel.activePlayers.any(
        (player) => player.displayName == 'Tess' && !player.isArchived,
      ),
      isTrue,
    );

    await environment.archivePlayer(playerId: createdPlayer.id);

    final afterArchiveModel = await environment.loadPlayersScreenModel();
    expect(
      afterArchiveModel.activePlayers.any((player) => player.id == createdPlayer.id),
      isFalse,
    );
    expect(
      afterArchiveModel.archivedPlayers.any((player) => player.id == createdPlayer.id),
      isTrue,
    );

    await environment.unarchivePlayer(playerId: createdPlayer.id);

    final afterUnarchiveModel = await environment.loadPlayersScreenModel();
    expect(
      afterUnarchiveModel.activePlayers.any((player) => player.id == createdPlayer.id),
      isTrue,
    );
    expect(
      afterUnarchiveModel.archivedPlayers.any((player) => player.id == createdPlayer.id),
      isFalse,
    );
  });

  test('exact duplicate player names are blocked', () async {
    final environment = await AppBootstrap.initialize(
      templateCatalog: loadTestTemplateCatalog(),
    );

    expect(
      () => environment.createPlayer(displayName: 'Avery'),
      throwsA(isA<PlayerValidationException>()),
    );

    expect(
      () => environment.createPlayer(displayName: '  avery  '),
      throwsA(isA<PlayerValidationException>()),
    );
  });
}
