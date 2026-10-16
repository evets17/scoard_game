import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/application/models/backup/backup_check_result.dart';
import 'package:scoard_game/bootstrap/app_bootstrap.dart';
import 'package:scoard_game/bootstrap/app_environment.dart';
import 'package:scoard_game/bootstrap/app_restarter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_templates.dart';

void main() {
  late Directory folder;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    folder = Directory.systemTemp.createTempSync('restore_data');
  });

  tearDown(() => folder.deleteSync(recursive: true));

  /// The app on its data in [name], as at startup.
  Future<AppEnvironment> open(String name) => AppBootstrap.initialize(
        usePersistentStorage: true,
        templateCatalog: loadTestTemplateCatalog(),
        dataFolder: Directory('${folder.path}/$name')..createSync(),
      );

  Future<List<String>> playerNames(AppEnvironment environment) async => [
        for (final player in await environment.playerRepository.loadPlayers())
          player.displayName,
      ]..sort();

  test('a backup from one phone restores onto another', () async {
    final first = await open('first');
    await first.createPlayer(displayName: 'Avery');
    await first.createPlayer(displayName: 'Jules');
    final bytes = await first.dataBackup!.backUp();
    await first.dataBackup!.close();

    final second = await open('second');
    await second.createPlayer(displayName: 'Mina');

    final check = await second.dataBackup!.check(bytes);
    expect((check as BackupAccepted).summary.players, 2);
    expect((await second.dataBackup!.summarizeCurrent()).players, 1);

    final (restored, ok) = await restoreAndReopen(second, () => open('second'));
    expect(ok, isTrue);
    expect(await playerNames(restored), ['Avery', 'Jules']);
    // The replaced data is kept aside.
    expect(restored.dataBackup!.safetyCopy.existsSync(), isTrue);
    await restored.dataBackup!.close();
  });

  test('when the restored data will not open, the old data comes back', () async {
    final first = await open('first');
    await first.createPlayer(displayName: 'Avery');
    final bytes = await first.dataBackup!.backUp();
    await first.dataBackup!.close();

    final second = await open('second');
    await second.createPlayer(displayName: 'Mina');
    await second.dataBackup!.check(bytes);

    var opens = 0;
    final (environment, ok) = await restoreAndReopen(second, () {
      opens += 1;
      if (opens == 1) {
        throw StateError('Pretend the restored file failed to open.');
      }
      return open('second');
    });
    expect(ok, isFalse);
    expect(await playerNames(environment), ['Mina']);
    await environment.dataBackup!.close();
  });

  test('a refused file is not kept for restoring', () async {
    final environment = await open('only');
    final check = await environment.dataBackup!.check(
      Uint8List.fromList('not a backup'.codeUnits),
    );
    expect((check as BackupRefused).reason, BackupRefusal.notABackup);
    await expectLater(
      environment.dataBackup!.closeAndSwapIn(),
      throwsStateError,
    );
    await environment.dataBackup!.close();
  });

  test('the last backup date is remembered', () async {
    final environment = await open('only');
    expect(environment.dataBackup!.lastBackedUpAt, isNull);
    await environment.dataBackup!.recordBackedUp(DateTime(2026, 10, 15, 9));
    expect(environment.dataBackup!.lastBackedUpAt, DateTime(2026, 10, 15, 9));
    await environment.dataBackup!.close();
  });

  // Backups saved by earlier versions of the app must always restore:
  // opening one runs the real migrations on old data. When a slice raises
  // the database's schemaVersion, it may add a backup from the new version.
  test('a backup saved by schema 8 restores with everything in it', () async {
    final environment = await open('restored');
    final bytes = File('test/support/backups/schema_8.db').readAsBytesSync();
    expect(await environment.dataBackup!.check(bytes), isA<BackupAccepted>());

    final (restored, ok) =
        await restoreAndReopen(environment, () => open('restored'));
    expect(ok, isTrue);

    expect(await playerNames(restored), ['Avery', 'Jules', 'Mina']);
    final groups = await restored.playerRepository.loadGroups();
    expect(groups.single.name, 'Family');

    final history = await restored.sessionRepository.loadRecentSessions(
      limit: 10,
    );
    expect(
      history.map((game) => game.gameName),
      unorderedEquals(['Catan', 'Cascadia', 'Skyjo']),
    );

    final inProgress = await restored.sessionRepository.loadActiveSessions(
      limit: 10,
    );
    expect(inProgress.single.gameName, 'Wingspan');
    final game = await restored.loadQuickScoreActiveSession(
      sessionId: inProgress.single.id,
    );
    expect(game!.participantValues.first.enteredValues, {'final-score': 44});
    await restored.dataBackup!.close();
  });
}
