import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:scoard_game/application/models/templates/online_template_status.dart';
import 'package:scoard_game/application/repositories/online_template_repository.dart';
import 'package:scoard_game/core/templates/template_index.dart';
import 'package:scoard_game/core/templates/template_validator.dart';

/// Keeps online templates in a folder:
///
/// ```text
/// <root>/templates/<template>.json
/// <root>/templates/images/<picture>.png
/// <root>/status.json
/// ```
///
/// Files are written to a new folder that then replaces the old one, so a
/// crash part way through never leaves a half-written set.
class FileOnlineTemplateCache implements OnlineTemplateCache {
  FileOnlineTemplateCache(this.root);

  final Directory root;

  Directory get _templates => Directory('${root.path}/templates');
  Directory get _incoming => Directory('${root.path}/templates.new');
  Directory get _outgoing => Directory('${root.path}/templates.old');
  File get _status => File('${root.path}/status.json');

  @override
  Future<Map<String, String>> loadFiles() async {
    // A swap interrupted between its two renames leaves only the old set.
    final folder = await _templates.exists() ? _templates : _outgoing;
    if (!await folder.exists()) {
      return const {};
    }

    final files = <String, String>{};
    await for (final entity in folder.list()) {
      final name = entity.uri.pathSegments.last;
      if (entity is File && isTemplateFilePath(name)) {
        files[name] = await entity.readAsString();
      }
    }
    return files;
  }

  @override
  Future<Map<String, Uint8List>> loadImages() async {
    final folder = Directory(
      '${(await _templates.exists() ? _templates : _outgoing).path}/images',
    );
    if (!await folder.exists()) {
      return const {};
    }
    return {
      await for (final entity in folder.list())
        if (entity is File && templateImagePattern.hasMatch(entity.uri.pathSegments.last))
          entity.uri.pathSegments.last: await entity.readAsBytes(),
    };
  }

  @override
  Future<void> replaceFiles(
    Map<String, String> files, {
    Map<String, Uint8List> images = const {},
  }) async {
    await root.create(recursive: true);
    if (await _incoming.exists()) {
      await _incoming.delete(recursive: true);
    }
    await _incoming.create();
    for (final entry in files.entries) {
      await File('${_incoming.path}/${entry.key}').writeAsString(entry.value);
    }
    if (images.isNotEmpty) {
      final imagesFolder = Directory('${_incoming.path}/images');
      await imagesFolder.create();
      for (final entry in images.entries) {
        await File('${imagesFolder.path}/${entry.key}').writeAsBytes(entry.value);
      }
    }

    if (await _outgoing.exists()) {
      await _outgoing.delete(recursive: true);
    }
    if (await _templates.exists()) {
      await _templates.rename(_outgoing.path);
    }
    await _incoming.rename(_templates.path);
    if (await _outgoing.exists()) {
      await _outgoing.delete(recursive: true);
    }
  }

  @override
  Future<OnlineTemplateStatus?> loadStatus() async {
    if (!await _status.exists()) {
      return null;
    }
    try {
      final json = jsonDecode(await _status.readAsString());
      return OnlineTemplateStatus.fromJson(json as Map<String, Object?>);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> saveStatus(OnlineTemplateStatus status) async {
    await root.create(recursive: true);
    final temporary = File('${_status.path}.new');
    await temporary.writeAsString(jsonEncode(status.toJson()));
    await temporary.rename(_status.path);
  }

  @override
  Future<void> clear() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  }
}
