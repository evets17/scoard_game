import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/bootstrap/app_bootstrap.dart';
import 'package:scoard_game/ui/round_score/round_score_flow_screen.dart';

import '../../support/test_templates.dart';

void main() {
  Future<void> startRackO(WidgetTester tester) async {
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
          preset: environment.templateCatalog.byId('rack-o'),
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

  Future<void> pickTiles(
    WidgetTester tester,
    String name,
    List<String> tiles,
    int total,
  ) async {
    await tester.tap(inRow(name, '–').first);
    await tester.pumpAndSettle();
    for (final tile in tiles) {
      await tester.tap(
        find.ancestor(of: find.text(tile), matching: find.byType(InkWell)).last,
      );
      await tester.pump();
    }
    await tester.tap(find.text('Replace -> $total'));
    await tester.pumpAndSettle();
  }

  testWidgets('the score sub label shows under the score, which stays', (
    tester,
  ) async {
    await startRackO(tester);

    await pickTiles(tester, 'Avery', ['Rack-O'], 75);
    await pickTiles(tester, 'Jules', ['30', '45'], 75);

    expect(inRow('Avery', '75'), findsWidgets);
    expect(inRow('Avery', 'Rack-o'), findsOneWidget);
    // The same 75 from cards alone is not a Rack-O.
    expect(inRow('Jules', '75'), findsWidgets);
    expect(inRow('Jules', 'Rack-o'), findsNothing);
    // The sub label fits under the number without making the card taller.
    expect(
      tester.getSize(rowFor('Avery')).height,
      tester.getSize(rowFor('Jules')).height,
    );

    // Changing the score another way drops the tiles, and the sub label.
    await tester.tap(
      find.descendant(
        of: rowFor('Avery'),
        matching: find.byTooltip('Increase score'),
      ),
    );
    await tester.pump();
    expect(inRow('Avery', 'Rack-o'), findsNothing);
    expect(inRow('Avery', '76'), findsWidgets);
  });
}
