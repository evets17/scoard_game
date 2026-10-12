import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/bootstrap/app_bootstrap.dart';
import 'package:scoard_game/bootstrap/app_environment.dart';
import 'package:scoard_game/ui/round_score/round_score_flow_screen.dart';

void main() {
  Future<void> openSetup(WidgetTester tester, AppEnvironment environment) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        // A new key builds a fresh screen, like starting another game.
        key: UniqueKey(),
        home: RoundScoreFlowScreen(
          loadRoundScoreSetupModel: environment.loadRoundScoreSetupModel,
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
  }

  Finder chip(String label) => find.widgetWithText(ChoiceChip, label);

  testWidgets('no group chips until a group exists', (tester) async {
    final environment = await AppBootstrap.initialize();
    await openSetup(tester, environment);

    expect(chip('All'), findsNothing);
  });

  testWidgets('a group chip filters available players and is remembered', (
    tester,
  ) async {
    final environment = await AppBootstrap.initialize();
    final family = await environment.createPlayerGroup(name: 'Family');
    await environment.setPlayerGroups(
      playerId: 'player-mina',
      groupIds: {family.id},
    );
    await environment.setPlayerGroups(
      playerId: 'player-rio',
      groupIds: {family.id},
    );

    await openSetup(tester, environment);
    expect(find.text('Avery'), findsOneWidget);

    await tester.tap(chip('Family'));
    await tester.pumpAndSettle();

    expect(find.text('Mina'), findsOneWidget);
    expect(find.text('Rio'), findsOneWidget);
    expect(find.text('Avery'), findsNothing);

    // Picking someone from the group moves them to Who's Playing.
    await tester.tap(find.text('Mina'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rio'));
    await tester.pumpAndSettle();
    expect(find.text('Everyone in this group is already in the game.'), findsOneWidget);

    // The next game starts with Family selected.
    await openSetup(tester, environment);
    expect(tester.widget<ChoiceChip>(chip('Family')).selected, isTrue);
    expect(find.text('Avery'), findsNothing);

    await tester.tap(chip('All'));
    await tester.pumpAndSettle();
    expect(find.text('Avery'), findsOneWidget);
  });
}
