import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:scoard_game/application/repositories/backup_files.dart';

/// The platform's own save and open screens. On Android they need no
/// storage permission: the player picks the place.
class FileBackupFiles implements BackupFiles {
  const FileBackupFiles();

  @override
  Future<bool> save({required String fileName, required Uint8List bytes}) async {
    final saved = await FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      dialogTitle: 'Save backup',
    );
    return saved != null;
  }

  @override
  Future<Uint8List?> open() async {
    // Any file: Android doesn't filter unknown file types reliably, and the
    // backup check decides what can be restored.
    final file = await FilePicker.pickFile(dialogTitle: 'Choose a backup');
    return file?.readAsBytes();
  }
}
