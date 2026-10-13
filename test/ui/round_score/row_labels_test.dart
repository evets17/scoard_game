import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/bootstrap/app_bootstrap.dart';
import 'package:scoard_game/bootstrap/app_environment.dart';
import 'package:scoard_game/ui/round_score/round_score_flow_screen.dart';

import '../../support/test_templates.dart';

void main() {
  Future<AppEnvironment> startFlip7(WidgetTester tester) async {
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
          preset: environment.templateCatalog.byId('flip-7'),
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

    for (final name in ['Avery', 'Jules', 'Mina']) {
      await tester.tap(find.text(name).first);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    return environment;
  }

  Finder rowFor(String name) =>
      find.ancestor(of: find.text(name), matching: find.byType(Card)).first;

  Finder inRow(String name, String text) =>
      find.descendant(of: rowFor(name), matching: find.text(text));

  Future<void> bust(WidgetTester tester, String name, {String from = '–'}) async {
    await tester.tap(inRow(name, from).first);
    await tester.pumpAndSettle();
    await tester.tap(
      find.ancestor(of: find.text('9'), matching: find.byType(InkWell)).last,
    );
    await tester.pump();
    await tester.tap(
      find.ancestor(of: find.text('Bust'), matching: find.byType(InkWell)).last,
    );
    await tester.pump();
    await tester.tap(find.text('Replace -> 0'));
    await tester.pumpAndSettle();
  }

  testWidgets('a bust shows on the row until the score changes another way', (
    tester,
  ) async {
    final environment = await startFlip7(tester);

    await bust(tester, 'Avery');

    expect(inRow('Avery', 'Bust'), findsOneWidget);
    expect(inRow('Jules', '–'), findsOneWidget);

    // The label is saved with the game in progress.
    final summary =
        (await environment.sessionRepository.loadActiveSessions(limit: 10))
            .firstWhere((summary) => summary.gameName == 'Flip 7');
    final saved =
        await environment.loadRoundScoreActiveSession(sessionId: summary.id);
    final averyEntry = saved!.currentRoundParticipantValues
        .firstWhere((participant) => participant.displayName == 'Avery');
    expect(averyEntry.entryLabels['round-score']?.text, 'Bust');

    // Changing the score with + clears the label.
    await tester.tap(
      find.descendant(
        of: rowFor('Avery'),
        matching: find.byTooltip('Increase score'),
      ),
    );
    await tester.pump();
    expect(inRow('Avery', 'Bust'), findsNothing);
    expect(inRow('Avery', '1'), findsWidgets);
  });

  testWidgets('labels belong to their round', (tester) async {
    await startFlip7(tester);

    await bust(tester, 'Jules');
    expect(inRow('Jules', 'Bust'), findsOneWidget);

    await tester.tap(find.text('Next Round >>'));
    await tester.pumpAndSettle();
    expect(find.text('Round 2'), findsOneWidget);
    expect(inRow('Jules', 'Bust'), findsNothing);
    expect(inRow('Jules', '–'), findsOneWidget);

    await tester.tap(find.text('<< Previous Round'));
    await tester.pumpAndSettle();
    expect(find.text('Round 1'), findsOneWidget);
    expect(inRow('Jules', 'Bust'), findsOneWidget);
  });
}
