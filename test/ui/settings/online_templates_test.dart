import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/bootstrap/app_bootstrap.dart';
import 'package:scoard_game/core/templates/template_catalog.dart';
import 'package:scoard_game/infrastructure/memory/memory_template_source_preferences.dart';
import 'package:scoard_game/ui/app/scoard_game_app.dart';
import 'package:scoard_game/ui/navigation/app_routes.dart';
import 'package:scoard_game/ui/settings/online_templates_section.dart';

import '../../support/fake_template_downloader.dart';
import '../../support/test_templates.dart';

String skyjo(void Function(Map<String, Object?> json) edit) {
  final json = jsonDecode(
    File('assets/templates/skyjo.json').readAsStringSync(),
  ) as Map<String, Object?>;
  edit(json);
  return jsonEncode(json);
}

void main() {
  late FakeTemplateDownloader downloader;

  Future<NavigatorState> openSettings(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final environment = await AppBootstrap.initialize(
      // A copy, so updates don't leak into other tests' catalog.
      templateCatalog: TemplateCatalog(loadTestTemplateCatalog().templates),
      templateDownloader: downloader,
      templateSourcePreferences: MemoryTemplateSourcePreferences(),
    );
    await tester.pumpWidget(ScoardGameApp(environment: environment));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings').first);
    await tester.pumpAndSettle();
    return tester.state<NavigatorState>(find.byType(Navigator));
  }

  setUp(() {
    downloader = FakeTemplateDownloader(
      files: {
        'skyjo.json': skyjo((json) => json['version'] = '2.2.0'),
        'bocce.json': skyjo((json) {
          json['id'] = 'bocce';
          json['name'] = 'Bocce';
        }),
      },
    );
  });

  testWidgets('online templates are off by default and checked when on', (
    tester,
  ) async {
    final navigator = await openSettings(tester);

    expect(find.text('Load templates online'), findsOneWidget);
    expect(find.text('Check now'), findsNothing);

    await tester.tap(find.text('Load templates online'));
    await tester.pumpAndSettle();

    expect(downloader.requests, hasLength(1));
    expect(find.text('Checked just now. Using 2 online templates.'), findsOneWidget);
    expect(find.text('Check now'), findsOneWidget);

    // Score a Game lists the template that is only online.
    navigator.pushNamed(AppRoutes.newGame);
    await tester.pumpAndSettle();
    expect(find.text('Bocce'), findsOneWidget);

    await tester.tap(find.text('Skyjo'));
    await tester.pumpAndSettle();
    expect(find.text('Template v2.2.0 · online'), findsOneWidget);
  });

  testWidgets('problems and failed checks are shown', (tester) async {
    await openSettings(tester);
    await tester.tap(find.text('Load templates online'));
    await tester.pumpAndSettle();

    downloader.files['broken.json'] = '{ not json';
    await tester.tap(find.text('Check now'));
    await tester.pumpAndSettle();

    expect(find.text('1 template has problems'), findsOneWidget);
    await tester.tap(find.text('1 template has problems'));
    await tester.pumpAndSettle();
    expect(find.text('broken.json'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    downloader.indexError = 'HTTP 404';
    await tester.tap(find.text('Check now'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Last check failed just now: HTTP 404. Using 2 online templates.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('the template URL can be changed and must be https', (
    tester,
  ) async {
    await openSettings(tester);
    await tester.tap(find.text('Load templates online'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Template URL'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'http://example.com/t');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter an https:// address.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'https://example.com/t');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('https://example.com/t/'), findsOneWidget);
    expect(downloader.requests.last.toString(), 'https://example.com/t/');
  });

  test('times read naturally', () {
    final now = DateTime(2026, 10, 13, 12);
    expect(describeWhen(now, now), 'just now');
    expect(describeWhen(now.subtract(const Duration(minutes: 1)), now),
        '1 minute ago');
    expect(describeWhen(now.subtract(const Duration(hours: 5)), now),
        '5 hours ago');
    expect(describeWhen(DateTime(2026, 10, 2), now), 'on 2 Oct');
  });
}
