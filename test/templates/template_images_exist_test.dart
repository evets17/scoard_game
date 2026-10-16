import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/application/services/templates/template_images.dart';

import '../support/test_templates.dart';

/// A missing picture would quietly fall back to text on the phone, so the
/// test run catches it instead.
void main() {
  test('every picture a template names is in the images folder', () {
    final folder = Directory(TemplateImages.bundledFolder);
    final present = folder.existsSync()
        ? {
            for (final file in folder.listSync().whereType<File>())
              file.uri.pathSegments.last,
          }
        : <String>{};

    for (final template in loadTestTemplateCatalog().templates) {
      final missing = template.images.difference(present);
      expect(
        missing,
        isEmpty,
        reason: '${template.id} names pictures that are not in '
            '${TemplateImages.bundledFolder}: ${missing.join(', ')}',
      );
    }
  });
}
