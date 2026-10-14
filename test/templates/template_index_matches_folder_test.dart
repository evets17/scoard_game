import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/core/templates/template_index.dart';

/// The app finds online templates through `index.json`, so a template
/// missing from it would never reach a phone.
void main() {
  test('index.json lists exactly the template files in the folder', () {
    final folder = Directory('assets/templates');
    final index = parseTemplateIndex(
      File('${folder.path}/$templateIndexFileName').readAsStringSync(),
    );
    final files = folder
        .listSync()
        .whereType<File>()
        .map((file) => file.uri.pathSegments.last)
        .where(isTemplateFilePath)
        .toSet();

    final missing = files.difference(index.files.toSet());
    final extra = index.files.toSet().difference(files);
    expect(
      missing,
      isEmpty,
      reason: 'add these to assets/templates/index.json: ${missing.join(', ')}',
    );
    expect(
      extra,
      isEmpty,
      reason: 'index.json lists files that do not exist: ${extra.join(', ')}',
    );
  });
}
