import 'dart:io';

import 'package:scoard_game/application/models/backup/backup_check_result.dart';
import 'package:scoard_game/application/models/backup/backup_summary.dart';
import 'package:scoard_game/infrastructure/persistence/db/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

/// Checks that the database file at [path] is a Scoard database this app
/// can open, and counts what it holds. Opens it read only, so the file is
/// never changed.
///
/// [schemaVersion] is this app's database version; a file from a newer one
/// is refused.
BackupCheckResult checkBackupFile(String path, {required int schemaVersion}) {
  final Database database;
  try {
    database = sqlite3.open(path, mode: OpenMode.readOnly);
  } on SqliteException {
    return const BackupRefused(BackupRefusal.notABackup);
  }

  try {
    int pragma(String name) =>
        database.select('PRAGMA $name').first.values.first! as int;

    // SQLite only finds out it is not a database on the first read.
    final int applicationId;
    try {
      applicationId = pragma('application_id');
    } on SqliteException {
      return const BackupRefused(BackupRefusal.notABackup);
    }
    if (applicationId != scoardApplicationId) {
      return const BackupRefused(BackupRefusal.notABackup);
    }
    if (pragma('user_version') > schemaVersion) {
      return const BackupRefused(BackupRefusal.newerApp);
    }

    final integrity = database.select('PRAGMA integrity_check');
    if (integrity.length != 1 || integrity.first.values.first != 'ok') {
      return const BackupRefused(BackupRefusal.damaged);
    }

    return BackupAccepted(_summarize(database));
  } on SqliteException {
    return const BackupRefused(BackupRefusal.damaged);
  } finally {
    database.close();
  }
}

/// Counts what the database at [path] holds, for the confirmation's "This
/// phone" column.
BackupSummary summarizeDatabaseFile(String path) {
  final database = sqlite3.open(path, mode: OpenMode.readOnly);
  try {
    return _summarize(database);
  } finally {
    database.close();
  }
}

BackupSummary _summarize(Database database) {
  // An older backup may be from before some tables existed.
  final tables = {
    for (final row in database.select(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    ))
      row['name'] as String,
  };
  int? single(String table, String expression) {
    if (!tables.contains(table)) {
      return null;
    }
    return database.select('SELECT $expression FROM $table').first.values.first
        as int?;
  }

  // Drift saves dates as Unix seconds.
  final latest = [
    single('quick_score_sessions_table', 'MAX(completed_at)'),
    single('round_score_sessions_table', 'MAX(completed_at)'),
    single('active_sessions_table', 'MAX(updated_at)'),
  ].whereType<int>().fold<int?>(
        null,
        (latest, value) => latest == null || value > latest ? value : latest,
      );

  return BackupSummary(
    players: single('players_table', 'COUNT(*)') ?? 0,
    finishedGames: (single('quick_score_sessions_table', 'COUNT(*)') ?? 0) +
        (single('round_score_sessions_table', 'COUNT(*)') ?? 0),
    gamesInProgress: single('active_sessions_table', 'COUNT(*)') ?? 0,
    latestGameAt: latest == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(latest * 1000),
  );
}

/// Files SQLite may keep beside a database while it is open.
List<File> _companionFiles(File database) => [
      for (final suffix in ['-wal', '-shm', '-journal'])
        File('${database.path}$suffix'),
    ];

/// Puts [replacement] in place of the closed database at [database]. The
/// current database is moved to [safetyCopy] first, replacing any earlier
/// one, so it can be put back.
void swapInDatabaseFile({
  required File database,
  required File replacement,
  required File safetyCopy,
}) {
  if (safetyCopy.existsSync()) {
    safetyCopy.deleteSync();
  }
  if (database.existsSync()) {
    database.renameSync(safetyCopy.path);
  }
  for (final file in _companionFiles(database)) {
    if (file.existsSync()) {
      file.deleteSync();
    }
  }
  // A copy, not a rename: the replacement may be in another folder.
  replacement.copySync(database.path);
  replacement.deleteSync();
}

/// Puts the database moved aside by [swapInDatabaseFile] back, after a
/// restore that failed. The database must be closed.
void putBackSafetyCopyFile({
  required File database,
  required File safetyCopy,
}) {
  if (!safetyCopy.existsSync()) {
    return;
  }
  for (final file in [database, ..._companionFiles(database)]) {
    if (file.existsSync()) {
      file.deleteSync();
    }
  }
  safetyCopy.renameSync(database.path);
}
