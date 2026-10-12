import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/bootstrap/app_bootstrap.dart';
import 'package:scoard_game/ui/round_score/round_score_flow_screen.dart';

import '../../support/test_templates.dart';

void main() {
  Future<void> startCornhole(WidgetTester tester) async {
    final environment = await AppBootstrap.initialize(
      templateCatalog: loadTestTemplateCatalog(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RoundScoreFlowScreen(
          loadRoundScoreSetupModel: environment.loadRoundScoreSetupModel,
          preset: environment.templateCatalog.byId('cornhole'),
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

    await tester.tap(find.text('Avery').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jules').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  }

  Finder rowFor(String name) =>
      find.ancestor(of: find.text(name), matching: find.byType(Card)).first;

  // The shaded running-total box is the row's only 20-point text.
  String totalFor(WidgetTester tester, String name) {
    final texts = tester
        .widgetList<Text>(
          find.descendant(of: rowFor(name), matching: find.byType(Text)),
        )
        .where((text) => text.style?.fontSize == 20);
    return texts.single.data!;
  }

  Future<void> increase(WidgetTester tester, String name, int times) async {
    for (var tap = 0; tap < times; tap++) {
      await tester.tap(
        find.descendant(
          of: rowFor(name),
          matching: find.byTooltip('Increase score'),
        ),
      );
      await tester.pump();
    }
  }

  testWidgets('Cornhole totals use cancellation scoring', (tester) async {
    await startCornhole(tester);

    // Inning 1: Avery 7, Jules 4. Only Avery scores, and only 3.
    await increase(tester, 'Avery', 7);
    expect(totalFor(tester, 'Avery'), '7');

    await increase(tester, 'Jules', 4);
    // Jules's entry changes Avery's total too.
    expect(totalFor(tester, 'Avery'), '3');
    expect(totalFor(tester, 'Jules'), '0');

    await tester.tap(find.text('Next Round >>'));
    await tester.pumpAndSettle();
    expect(totalFor(tester, 'Avery'), '3');
    expect(totalFor(tester, 'Jules'), '0');

    // Inning 2: Jules enters two in the hole and one on the board (7) with
    // the Bags picker; Avery gets 2.
    await tester.tap(
      find.descendant(of: rowFor('Jules'), matching: find.text('0')).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Bags'), findsOneWidget);
    await tester.tap(find.text('Hole'));
    await tester.pump();
    await tester.tap(find.text('Hole'));
    await tester.pump();
    await tester.tap(find.text('Board'));
    await tester.pump();
    await tester.tap(find.text('Replace -> 7'));
    await tester.pumpAndSettle();

    await increase(tester, 'Avery', 2);

    expect(totalFor(tester, 'Avery'), '3');
    expect(totalFor(tester, 'Jules'), '5');

    // Score sort puts the leader by points scored first.
    await tester.tap(find.byTooltip('Sort players'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Score').last);
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(rowFor('Jules')).dy,
      lessThan(tester.getTopLeft(rowFor('Avery')).dy),
    );

    await tester.tap(find.text('Game Over'));
    await tester.pumpAndSettle();

    expect(find.text('Final Result'), findsOneWidget);
    // Jules wins 5 to 3.
    expect(find.text('Jules'), findsNWidgets(2));
    expect(find.text('5'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });
}
