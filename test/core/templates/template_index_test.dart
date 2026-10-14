import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/core/templates/template_index.dart';

void main() {
  test('reads the listed template files', () {
    final index = parseTemplateIndex(
      '{"indexVersion": 1, "templates": ["skyjo.json", "flip-7.json"]}',
    );

    expect(index.files, ['skyjo.json', 'flip-7.json']);
  });

  test('rejects anything that is not a plain template file name', () {
    for (final name in [
      '../secrets.json',
      'nested/skyjo.json',
      'Skyjo.json',
      'skyjo.txt',
      'index',
    ]) {
      expect(
        () => parseTemplateIndex(
          '{"indexVersion": 1, "templates": ["$name"]}',
        ),
        throwsFormatException,
        reason: name,
      );
    }
  });

  test('rejects unknown versions, bad JSON, and duplicates', () {
    for (final source in [
      '{"indexVersion": 2, "templates": []}',
      '{"templates": []}',
      '{ not json',
      '[]',
      '{"indexVersion": 1, "templates": ["a.json", "a.json"]}',
      '{"indexVersion": 1, "templates": "a.json"}',
    ]) {
      expect(
        () => parseTemplateIndex(source),
        throwsFormatException,
        reason: source,
      );
    }
  });

  test('the index is not a template file', () {
    expect(isTemplateFilePath('assets/templates/skyjo.json'), isTrue);
    expect(isTemplateFilePath('assets/templates/index.json'), isFalse);
    expect(isTemplateFilePath(r'assets\templates\index.json'), isFalse);
    expect(isTemplateFilePath('assets/templates/notes.md'), isFalse);
  });
}
