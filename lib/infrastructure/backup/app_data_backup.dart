import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:scoard_game/application/models/backup/backup_check_result.dart';
import 'package:scoard_game/application/models/backup/backup_summary.dart';
import 'package:scoard_game/infrastructure/backup/database_backup.dart';
import 'package:scoard_game/infrastructure/persistence/db/app_database.dart';
import 'package:scoard_game/infrastructure/persistence/preferences/backup_preference_store.dart';

/// Backs up the app's database and restores a backup over it.
///
/// A backup is a copy of the database file. Restoring checks a picked file
/// first, then, once the player confirms, swaps it in with the current
/// database kept as a safety copy. The app then opens the restored file
/// afresh, which upgrades it if it came from an older version.
class AppDataBackup {
  AppDataBackup({
    required AppDatabase database,
    required this.databaseFile,
    required Directory workFolder,
    required BackupPreferenceStore? preferences,
  })  : _database = database,
        _workFolder = workFolder,
        _preferences = preferences;

  final AppDatabase _database;
  final File databaseFile;
  final Directory _workFolder;
  final BackupPreferenceStore? _preferences;

  /// When the data was last backed up, or null if it never has been.
  DateTime? get lastBackedUpAt => _preferences?.loadLastBackedUpAt();

  /// Notes that a backup was just saved.
  Future<void> recordBackedUp(DateTime at) async {
    await _preferences?.saveLastBackedUpAt(at);
  }

  /// The database as it was before the last restore, kept beside it so an
  /// accidental restore can be undone by hand.
  File get safetyCopy => File(
        p.join(databaseFile.parent.path, 'scoard_game.before_restore.sqlite'),
      );

  File get _candidate => File(p.join(_workFolder.path, 'restore_candidate.db'));

  /// A backup: a consistent copy of the database, taken while it stays open.
  Future<Uint8List> backUp() async {
    _workFolder.createSync(recursive: true);
    final copy = File(p.join(_workFolder.path, 'backup.db'));
    if (copy.existsSync()) {
      copy.deleteSync();
    }
    try {
      await _database.copyTo(copy);
      return copy.readAsBytesSync();
    } finally {
      if (copy.existsSync()) {
        copy.deleteSync();
      }
    }
  }

  /// Checks a picked backup. One that passes is kept ready for
  /// [closeAndSwapIn].
  Future<BackupCheckResult> check(Uint8List bytes) async {
    _workFolder.createSync(recursive: true);
    _candidate.writeAsBytesSync(bytes, flush: true);
    final result = checkBackupFile(
      _candidate.path,
      schemaVersion: _database.schemaVersion,
    );
    if (result is BackupRefused) {
      _candidate.deleteSync();
    }
    return result;
  }

  /// What this phone holds now, to show beside a backup.
  Future<BackupSummary> summarizeCurrent() async {
    // Makes sure the database is open, so the file is there to read.
    await _database.customSelect('SELECT 1').get();
    return summarizeDatabaseFile(databaseFile.path);
  }

  /// Closes the database and puts the checked backup in its place. Nothing
  /// may use this app data afterwards: the app opens the restored file
  /// afresh.
  Future<void> closeAndSwapIn() async {
    if (!_candidate.existsSync()) {
      throw StateError('No checked backup to restore.');
    }
    await _database.close();
    swapInDatabaseFile(
      database: databaseFile,
      replacement: _candidate,
      safetyCopy: safetyCopy,
    );
  }

  /// Puts the database from before the restore back, after the restored
  /// file failed to open. The database must be closed.
  void putBackSafetyCopy() {
    putBackSafetyCopyFile(database: databaseFile, safetyCopy: safetyCopy);
  }

  Future<void> close() => _database.close();
}
