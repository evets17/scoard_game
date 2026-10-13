import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/bootstrap/app_bootstrap.dart';
import 'package:scoard_game/ui/round_score/round_score_flow_screen.dart';

import '../../support/test_templates.dart';

void main() {
  Future<void> startSkyjo(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final environment = await AppBootstrap.initialize(
      templateCatalog: loadTestTemplateCatalog(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: RoundScoreFlowScreen(
          loadRoundScoreSetupModel: environment.loadRoundScoreSetupModel,
          preset: environment.templateCatalog.byId('skyjo'),
          createPlayer: environment.createPlayer,
          renamePlayer: environment.renamePlayer,
          stayAwakeController: environment.stayAwakeController,
          rememberSetupPlayerGroup: environment.rememberSetupPlayerGroup,
          saveRoundScoreSession: environment.saveRoundScoreSession,
          saveRoundScoreActiveSession: environment.saveRoundScoreActiveSession,
          deleteActiveSession: environment.deleteActiveSession,
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final name in ['Avery', 'Jules']) {
      await tester.tap(find.text(name).first);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  }

  Finder rowFor(String name) =>
      find.ancestor(of: find.text(name), matching: find.byType(Card)).first;

  Finder inRow(String name, String text) =>
      find.descendant(of: rowFor(name), matching: find.text(text));

  // The shaded running-total box is the row's only 20-point text.
  String totalFor(WidgetTester tester, String name) {
    return tester
        .widgetList<Text>(
          find.descendant(of: rowFor(name), matching: find.byType(Text)),
        )
        .where((text) => text.style?.fontSize == 20)
        .single
        .data!;
  }

  Future<void> score(WidgetTester tester, String name, List<String> cards) async {
    await tester.tap(inRow(name, '–').first);
    await tester.pumpAndSettle();
    for (final card in cards) {
      await tester.tap(
        find.ancestor(of: find.text(card), matching: find.byType(InkWell)).last,
      );
      await tester.pump();
    }
    final total = cards.fold<int>(0, (sum, card) => sum + int.parse(card));
    await tester.tap(find.text('Replace -> $total'));
    await tester.pumpAndSettle();
  }

  Future<void> toggleWentOutFirst(WidgetTester tester, String name, String shown) async {
    await tester.tap(inRow(name, shown).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Went out first'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  }

  testWidgets('going out first doubles a score that is not lowest outright', (
    tester,
  ) async {
    await startSkyjo(tester);

    await score(tester, 'Avery', ['10']);
    await score(tester, 'Jules', ['4']);
    expect(totalFor(tester, 'Avery'), '10');

    // Marking takes effect straight away, even though the sheet is cancelled.
    await toggleWentOutFirst(tester, 'Avery', '10');

    expect(inRow('Avery', 'Out'), findsOneWidget);
    expect(totalFor(tester, 'Avery'), '20');

    // Only one player can go out first: marking Jules moves it.
    await toggleWentOutFirst(tester, 'Jules', '4');

    expect(inRow('Avery', 'Out'), findsNothing);
    expect(inRow('Jules', 'Out'), findsOneWidget);
    expect(totalFor(tester, 'Avery'), '10');
    expect(totalFor(tester, 'Jules'), '4');
  });
}
