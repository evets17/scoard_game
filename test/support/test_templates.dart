import 'dart:io';

import 'package:scoard_game/core/templates/template_catalog.dart';

TemplateCatalog? _cached;

/// The bundled templates, read straight from disk.
///
/// Tests pass this to `AppBootstrap.initialize` so they don't depend on
/// loading Flutter assets, which stalls inside widget tests' fake clock.
TemplateCatalog loadTestTemplateCatalog() {
  return _cached ??= () {
    final files = Directory('assets/templates')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'));
    final result = loadTemplateCatalog({
      for (final file in files) file.path: file.readAsStringSync(),
    });
    if (result.hasProblems) {
      throw StateError(result.describeProblems());
    }
    return result.catalog;
  }();
}
