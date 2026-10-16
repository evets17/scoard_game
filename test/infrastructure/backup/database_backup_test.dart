import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/application/models/backup/backup_check_result.dart';
import 'package:scoard_game/infrastructure/backup/database_backup.dart';
import 'package:scoard_game/infrastructure/persistence/db/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Directory folder;

  setUp(() => folder = Directory.systemTemp.createTempSync('database_backup'));
  tearDown(() => folder.deleteSync(recursive: true));

  Future<int> applicationIdOf(AppDatabase database) async {
    final row = await database.customSelect('PRAGMA application_id').getSingle();
    return row.read<int>('application_id');
  }

  test('every database is marked as Scoard\'s, including older ones', () async {
    final file = File('${folder.path}/app.db');
    final database = AppDatabase.forTesting(NativeDatabase(file));
    expect(await applicationIdOf(database), scoardApplicationId);

    // A database from before the mark gets it the next time it opens.
    await database.customStatement('PRAGMA application_id = 0');
    await database.close();
    final reopened = AppDatabase.forTesting(NativeDatabase(file));
    expect(await applicationIdOf(reopened), scoardApplicationId);
    await reopened.close();
  });

  test('a copy holds the same data, taken while the database is open', () async {
    final database = AppDatabase.forTesting(
      NativeDatabase(File('${folder.path}/app.db')),
    );
    await database.into(database.playersTable).insert(
          PlayersTableCompanion.insert(
            id: 'avery',
            displayName: 'Avery',
            normalizedDisplayName: 'avery',
            createdAt: DateTime(2026, 10, 15),
          ),
        );

    final copy = File('${folder.path}/backup.db');
    await database.copyTo(copy);
    // Still usable afterwards.
    expect(await database.select(database.playersTable).get(), hasLength(1));
    await database.close();

    final restored = AppDatabase.forTesting(NativeDatabase(copy));
    final players = await restored.select(restored.playersTable).get();
    expect(players.single.displayName, 'Avery');
    expect(await applicationIdOf(restored), scoardApplicationId);
    await restored.close();
  });

  group('checking a picked file', () {
    late File backup;

    setUp(() async {
      final database = AppDatabase.forTesting(
        NativeDatabase(File('${folder.path}/app.db')),
      );
      for (final name in ['Avery', 'Jules']) {
        await database.into(database.playersTable).insert(
              PlayersTableCompanion.insert(
                id: name.toLowerCase(),
                displayName: name,
                normalizedDisplayName: name.toLowerCase(),
                createdAt: DateTime(2026, 10, 1),
              ),
            );
      }
      await database.saveQuickScoreResult(
        sessionId: 'finished',
        templateId: 'quick-final-score-basic',
        templateDisplayName: 'Catan',
        winnerRule: 'highestScoreWins',
        optionsJson: '[]',
        completedAt: DateTime(2026, 10, 12, 20),
        participantValues: const [],
        playerResults: const [],
      );
      backup = File('${folder.path}/backup.db');
      await database.copyTo(backup);
      await database.close();
    });

    BackupCheckResult check(File file) =>
        checkBackupFile(file.path, schemaVersion: 8);

    test('a Scoard backup passes, with what it holds', () {
      final summary = (check(backup) as BackupAccepted).summary;
      expect(summary.players, 2);
      expect(summary.finishedGames, 1);
      expect(summary.gamesInProgress, 0);
      expect(summary.latestGameAt, DateTime(2026, 10, 12, 20));
      expect(summarizeDatabaseFile(backup.path).players, 2);
    });

    BackupRefusal? refusalFor(File file) => switch (check(file)) {
          BackupRefused(:final reason) => reason,
          BackupAccepted() => null,
        };

    test('a text file or another app\'s database is not a backup', () {
      final text = File('${folder.path}/notes.db')
        ..writeAsStringSync('These are not the scores you are looking for.');
      expect(refusalFor(text), BackupRefusal.notABackup);

      sqlite3.open('${folder.path}/other.db')
        ..execute('CREATE TABLE things (id INTEGER)')
        ..close();
      expect(refusalFor(File('${folder.path}/other.db')), BackupRefusal.notABackup);

      expect(refusalFor(File('${folder.path}/missing.db')), BackupRefusal.notABackup);
    });

    test('a backup from a newer app is refused', () {
      sqlite3.open(backup.path)
        ..execute('PRAGMA user_version = 9')
        ..close();
      expect(refusalFor(backup), BackupRefusal.newerApp);
    });

    test('a damaged backup is refused', () {
      // Scribble over the second page, past the header that says what the
      // file is.
      final bytes = backup.readAsBytesSync();
      for (var index = 4096; index < 4096 + 512; index++) {
        bytes[index] = 0x5A;
      }
      backup.writeAsBytesSync(bytes);
      expect(refusalFor(backup), BackupRefusal.damaged);
    });
  });
}
