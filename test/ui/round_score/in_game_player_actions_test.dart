import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/bootstrap/app_bootstrap.dart';
import 'package:scoard_game/ui/round_score/round_score_flow_screen.dart';

void main() {
  Future<void> startGame(WidgetTester tester) async {
    final environment = await AppBootstrap.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: RoundScoreFlowScreen(
          loadRoundScoreSetupModel: environment.loadRoundScoreSetupModel,
          createPlayer: environment.createPlayer,
          renamePlayer: environment.renamePlayer,
          stayAwakeController: environment.stayAwakeController,
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

  testWidgets('help button opens scoring help instead of inline helper text', (
    tester,
  ) async {
    await startGame(tester);

    expect(find.textContaining('Enter the scores for round'), findsNothing);

    await tester.tap(find.byTooltip('Help'));
    await tester.pumpAndSettle();

    expect(find.text('Help'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Rounds'), 200);
    expect(find.text('Rounds'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Players'), 200);
    expect(find.textContaining('Tap a player\'s name'), findsWidgets);
  });

  testWidgets('tapping a player name offers edit and switch', (
    tester,
  ) async {
    await startGame(tester);

    await tester.tap(find.text('Avery'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Avery'), findsOneWidget);
    expect(find.text('Switch player'), findsOneWidget);
  });

  testWidgets('editing a player in game renames them on the score screen', (
    tester,
  ) async {
    await startGame(tester);

    await tester.tap(find.text('Jules'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Jules'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Julia');
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Round 1'), findsOneWidget);
    expect(find.text('Julia'), findsOneWidget);
    expect(find.text('Jules'), findsNothing);
  });

  testWidgets('switching a player keeps their scores in the game', (
    tester,
  ) async {
    await startGame(tester);

    await tester.tap(find.byTooltip('Increase score').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next Round >>'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Avery'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Switch player'));
    await tester.pumpAndSettle();

    expect(find.text('Replace Avery with'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Jules'),
      ),
      findsNothing,
    );

    await tester.tap(find.text('Mina'));
    await tester.pumpAndSettle();

    expect(find.text('Round 2'), findsOneWidget);
    expect(find.text('Mina'), findsOneWidget);
    expect(find.text('Avery'), findsNothing);

    await tester.tap(find.text('Game Over'));
    await tester.pumpAndSettle();

    expect(find.text('Final Result'), findsOneWidget);
    expect(find.text('Mina'), findsWidgets);
    expect(find.text('Avery'), findsNothing);
  });
}
