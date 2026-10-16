import 'dart:typed_data';

import 'package:scoard_game/application/repositories/backup_files.dart';

/// Hands back [toOpen] instead of opening the system screens, and keeps what
/// was saved.
class FakeBackupFiles implements BackupFiles {
  FakeBackupFiles({this.toOpen});

  /// What the player "picks" on Restore; null is cancelling.
  Uint8List? toOpen;

  String? savedName;
  Uint8List? savedBytes;

  @override
  Future<bool> save({required String fileName, required Uint8List bytes}) async {
    savedName = fileName;
    savedBytes = bytes;
    return true;
  }

  @override
  Future<Uint8List?> open() async => toOpen;
}
