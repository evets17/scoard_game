import 'dart:typed_data';

/// The system screens for saving a backup and picking one to restore.
abstract class BackupFiles {
  /// Lets the player choose where to save [bytes], suggesting [fileName].
  /// Returns false if they cancelled.
  Future<bool> save({required String fileName, required Uint8List bytes});

  /// Lets the player pick a file, and returns what is in it, or null if
  /// they cancelled.
  Future<Uint8List?> open();
}
