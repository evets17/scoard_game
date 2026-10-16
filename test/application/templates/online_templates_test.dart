import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/application/models/scoring/template_origin.dart';
import 'package:scoard_game/application/services/templates/online_templates.dart';
import 'package:scoard_game/application/services/templates/template_images.dart';
import 'package:scoard_game/core/templates/template_catalog.dart';
import 'package:scoard_game/infrastructure/memory/memory_online_template_cache.dart';
import 'package:scoard_game/infrastructure/memory/memory_template_source_preferences.dart';

import '../../support/fake_template_downloader.dart';

/// The bundled Skyjo template, changed by [edit].
String skyjo([void Function(Map<String, Object?> json)? edit]) {
  final json = jsonDecode(
    File('assets/templates/skyjo.json').readAsStringSync(),
  ) as Map<String, Object?>;
  // Pictures are tested on their own; the sample asks for none.
  json.remove('card');
  edit?.call(json);
  return jsonEncode(json);
}

/// A new template that is only online.
String bocce() => skyjo((json) {
      json['id'] = 'bocce';
      json['name'] = 'Bocce';
    });

void main() {
  late TemplateCatalog catalog;
  late FakeTemplateDownloader downloader;
  late MemoryOnlineTemplateCache cache;
  late MemoryTemplateSourcePreferences preferences;
  late TemplateImages images;
  var clock = DateTime(2026, 10, 13, 9);

  OnlineTemplates create({bool enabled = true}) {
    return OnlineTemplates(
      catalog: catalog,
      downloader: downloader,
      cache: cache,
      preferences: preferences,
      enabledByDefault: enabled,
      images: images,
      now: () => clock,
    );
  }

  setUp(() {
    catalog = loadTemplateCatalog({'skyjo.json': skyjo()}).catalog;
    downloader = FakeTemplateDownloader();
    cache = MemoryOnlineTemplateCache();
    preferences = MemoryTemplateSourcePreferences();
    images = TemplateImages();
    clock = DateTime(2026, 10, 13, 9);
  });

  test('a check applies changed and new templates', () async {
    downloader.files = {
      'skyjo.json': skyjo((json) => json['description'] = 'Online wording'),
      'bocce.json': bocce(),
    };
    final online = create();
    await online.loadSaved();

    await online.checkNow();

    expect(catalog.byId('skyjo').description, 'Online wording');
    expect(catalog.byId('skyjo').origin, TemplateOrigin.online);
    expect(catalog.maybeById('bocce'), isNotNull);
    expect(online.status!.templateCount, 2);
    expect(online.status!.lastUpdated, clock);
    expect(online.status!.problems, isEmpty);
    expect(downloader.requests.single.toString(), defaultTemplateUrl);
  });

  test('saved copies are used at the next start without a check', () async {
    downloader.files = {
      'skyjo.json': skyjo((json) => json['description'] = 'Online wording'),
    };
    final first = create();
    await first.loadSaved();
    await first.checkNow();

    catalog = loadTemplateCatalog({'skyjo.json': skyjo()}).catalog;
    downloader.indexError = 'offline';
    await create().loadSaved();

    expect(catalog.byId('skyjo').description, 'Online wording');
  });

  test('a bad file keeps its last good copy and is reported', () async {
    final online = create();
    await online.loadSaved();
    downloader.files = {
      'skyjo.json': skyjo((json) => json['description'] = 'Good'),
    };
    await online.checkNow();

    downloader.files = {
      'skyjo.json': skyjo((json) => json.remove('winner')),
    };
    clock = clock.add(const Duration(hours: 1));
    await online.checkNow();

    expect(catalog.byId('skyjo').description, 'Good');
    expect(online.status!.problems.keys, ['skyjo.json']);
    expect(online.status!.problems['skyjo.json']!.single, contains('winner'));
    // Nothing usable changed.
    expect(online.status!.lastUpdated, DateTime(2026, 10, 13, 9));
    expect(online.status!.lastChecked, clock);
  });

  test('a failed check changes nothing but the status', () async {
    final online = create();
    await online.loadSaved();
    downloader.files = {'bocce.json': bocce()};
    await online.checkNow();

    downloader.indexError = "Couldn't read index.json: timed out";
    await online.checkNow();

    expect(catalog.maybeById('bocce'), isNotNull);
    expect(online.status!.lastError, "Couldn't read index.json: timed out");
    expect(online.status!.templateCount, 1);
  });

  test('a template removed online falls back to the bundled one', () async {
    final online = create();
    await online.loadSaved();
    downloader.files = {
      'skyjo.json': skyjo((json) => json['description'] = 'Online wording'),
      'bocce.json': bocce(),
    };
    await online.checkNow();

    downloader.files = {};
    await online.checkNow();

    expect(catalog.byId('skyjo').origin, TemplateOrigin.bundled);
    expect(catalog.maybeById('bocce'), isNull);
  });

  test('a newer bundled version wins over an older online copy', () async {
    catalog = loadTemplateCatalog({
      'skyjo.json': skyjo((json) => json['version'] = '3.0.0'),
    }).catalog;
    downloader.files = {
      'skyjo.json': skyjo((json) => json['description'] = 'Older online'),
    };
    final online = create();
    await online.loadSaved();
    await online.checkNow();

    expect(catalog.byId('skyjo').version, '3.0.0');
    expect(catalog.byId('skyjo').origin, TemplateOrigin.bundled);
  });

  test('switching off goes back to bundled; on uses saved copies', () async {
    downloader.files = {'bocce.json': bocce()};
    final online = create();
    await online.loadSaved();
    await online.checkNow();

    await online.setEnabled(false);
    expect(catalog.maybeById('bocce'), isNull);
    expect(preferences.loadEnabled(), isFalse);

    downloader.indexError = 'offline';
    await online.setEnabled(true);
    expect(catalog.maybeById('bocce'), isNotNull);
  });

  test('when off, nothing is checked at start', () async {
    final online = create(enabled: false);
    await online.loadSaved();
    await online.checkOnStart();

    expect(downloader.requests, isEmpty);
  });

  test('a new URL clears saved copies and checks the new source', () async {
    downloader.files = {'bocce.json': bocce()};
    final online = create();
    await online.loadSaved();
    await online.checkNow();

    downloader.files = {};
    expect(await online.setUrl('https://example.com/games'), isNull);

    expect(online.url, 'https://example.com/games/');
    expect(preferences.loadUrl(), 'https://example.com/games/');
    expect(downloader.requests.last.toString(), 'https://example.com/games/');
    expect(catalog.maybeById('bocce'), isNull);
    expect(await cache.loadFiles(), isEmpty);

    await online.resetUrl();
    expect(online.isDefaultUrl, isTrue);
    expect(preferences.loadUrl(), isNull);
  });

  test('saved copies from another URL are not used', () async {
    downloader.files = {'bocce.json': bocce()};
    final first = create();
    await first.loadSaved();
    await first.checkNow();

    preferences = MemoryTemplateSourcePreferences(
      enabled: true,
      url: 'https://example.com/other/',
    );
    catalog = loadTemplateCatalog({'skyjo.json': skyjo()}).catalog;
    await create().loadSaved();

    expect(catalog.maybeById('bocce'), isNull);
    expect(await cache.loadFiles(), isEmpty);
  });

  test('only https addresses are accepted', () async {
    final online = create();
    expect(await online.setUrl('http://example.com/'), isNotNull);
    expect(await online.setUrl('not a url'), isNotNull);
    expect(online.isDefaultUrl, isTrue);

    expect(
      normalizeTemplateUrl(' https://example.com/a?x=1#y '),
      'https://example.com/a/',
    );
  });

  test('pictures come with online templates and are kept offline', () async {
    String withPicture(String picture) => skyjo((json) {
          ((json['lines']! as List<Object?>).first! as Map<String, Object?>)
              ['image'] = picture;
        });
    final bear = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 1]);
    downloader
      ..files = {'skyjo.json': withPicture('bear.png')}
      ..images = {'bear.png': bear};
    final online = create();
    await online.loadSaved();
    await online.checkNow();

    expect(downloader.imageRequests.single, {'bear.png'});
    expect(images.online('bear.png'), bear);
    expect(await cache.loadImages(), {'bear.png': bear});

    // A picture that fails keeps its last good copy and is reported.
    downloader.images = {};
    await online.checkNow();
    expect(images.online('bear.png'), bear);
    expect(online.status!.problems['images/bear.png'], isNotEmpty);

    // A picture no template uses any more is dropped.
    downloader.files = {'skyjo.json': skyjo()};
    await online.checkNow();
    expect(images.online('bear.png'), isNull);
    expect(await cache.loadImages(), isEmpty);
  });
}
