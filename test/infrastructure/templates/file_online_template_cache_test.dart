import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/application/models/templates/online_template_status.dart';
import 'package:scoard_game/infrastructure/templates/file_online_template_cache.dart';

void main() {
  late Directory temporary;
  late FileOnlineTemplateCache cache;

  setUp(() {
    temporary = Directory.systemTemp.createTempSync('online_templates_test');
    cache = FileOnlineTemplateCache(Directory('${temporary.path}/cache'));
  });

  tearDown(() => temporary.deleteSync(recursive: true));

  test('starts empty', () async {
    expect(await cache.loadFiles(), isEmpty);
    expect(await cache.loadStatus(), isNull);
  });

  test('replacing files swaps the whole set', () async {
    await cache.replaceFiles({'a.json': 'A', 'b.json': 'B'});
    expect(await cache.loadFiles(), {'a.json': 'A', 'b.json': 'B'});

    await cache.replaceFiles({'b.json': 'B2'});
    expect(await cache.loadFiles(), {'b.json': 'B2'});
    expect(
      Directory('${temporary.path}/cache').listSync().map(
            (entity) => entity.uri.pathSegments.where((s) => s.isNotEmpty).last,
          ),
      ['templates'],
    );
  });

  test('a swap interrupted between renames still reads the old set', () async {
    await cache.replaceFiles({'a.json': 'A'});
    Directory('${temporary.path}/cache/templates')
        .renameSync('${temporary.path}/cache/templates.old');

    expect(await cache.loadFiles(), {'a.json': 'A'});
  });

  test('status round-trips, and clear removes everything', () async {
    final status = OnlineTemplateStatus(
      sourceUrl: 'https://example.com/',
      lastChecked: DateTime.utc(2026, 10, 13, 9),
      lastUpdated: DateTime.utc(2026, 10, 12),
      templateCount: 2,
      lastError: 'timed out',
      problems: const {
        'bad.json': ['id: missing'],
      },
    );
    await cache.saveStatus(status);
    await cache.replaceFiles({'a.json': 'A'});

    final loaded = (await cache.loadStatus())!;
    expect(loaded.toJson(), status.toJson());

    await cache.clear();
    expect(await cache.loadFiles(), isEmpty);
    expect(await cache.loadStatus(), isNull);
  });

  test('pictures are saved and replaced with the templates', () async {
    final bear = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 1]);
    await cache.replaceFiles({'a.json': 'A'}, images: {'bear.png': bear});
    expect(await cache.loadImages(), {'bear.png': bear});

    await cache.replaceFiles({'a.json': 'A'});
    expect(await cache.loadImages(), isEmpty);
    expect(await cache.loadFiles(), {'a.json': 'A'});
  });
}
