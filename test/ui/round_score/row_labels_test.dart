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
    expect(averyEntry.entryPicks['round-score']?.tiles, ['9', 'Bust']);

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

  testWidgets('reopening a card-scored row shows its cards to adjust', (
    tester,
  ) async {
    await startFlip7(tester);

    await bust(tester, 'Mina');

    // Reopen Mina's sheet: the cards she was scored with are still there.
    await tester.tap(inRow('Mina', 'Bust'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove 9'), findsOneWidget);
    expect(find.byTooltip('Remove Bust'), findsOneWidget);

    // It was not a bust after all: take it back and replace.
    await tester.tap(find.byTooltip('Remove Bust'));
    await tester.pump();
    expect(find.text('= 9'), findsOneWidget);
    await tester.tap(find.text('Replace -> 9'));
    await tester.pumpAndSettle();

    expect(inRow('Mina', 'Bust'), findsNothing);
    expect(inRow('Mina', '9'), findsWidgets);

    // Changing the score another way drops the cards.
    await tester.tap(
      find.descendant(
        of: rowFor('Mina'),
        matching: find.byTooltip('Increase score'),
      ),
    );
    await tester.pump();
    await tester.tap(inRow('Mina', '10').first);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove 9'), findsNothing);
  });

  testWidgets('a Flip 7 shows a badge and keeps the score visible', (
    tester,
  ) async {
    await startFlip7(tester);

    await tester.tap(inRow('Avery', '–').first);
    await tester.pumpAndSettle();
    for (final card in ['1', '2', '3', '4', '5', '6', '7']) {
      await tester.tap(
        find.ancestor(of: find.text(card), matching: find.byType(InkWell)).last,
      );
      await tester.pump();
    }
    await tester.tap(find.text('Replace -> 43'));
    await tester.pumpAndSettle();

    expect(inRow('Avery', '7!'), findsOneWidget);
    expect(inRow('Avery', '43'), findsWidgets);
  });
}
