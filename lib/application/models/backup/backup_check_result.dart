import 'package:scoard_game/application/models/backup/backup_summary.dart';

/// Why a picked file can't be restored.
enum BackupRefusal {
  /// Not an SQLite database, or not Scoard's.
  notABackup,

  /// Made by a newer version of the app, with a schema this one can't read.
  newerApp,

  /// A Scoard database that fails SQLite's integrity check.
  damaged,
}

/// The outcome of checking a picked file: what it holds, or why it can't
/// be restored.
sealed class BackupCheckResult {
  const BackupCheckResult();
}

class BackupAccepted extends BackupCheckResult {
  const BackupAccepted(this.summary);

  final BackupSummary summary;
}

class BackupRefused extends BackupCheckResult {
  const BackupRefused(this.reason);

  final BackupRefusal reason;
}
