import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/bootstrap/app_bootstrap.dart';
import 'package:scoard_game/ui/round_score/round_score_flow_screen.dart';

void main() {
  Future<void> openSetup(WidgetTester tester) async {
    final environment = await AppBootstrap.initialize();

    await tester.pumpWidget(
      MaterialApp(
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

  Future<void> selectPlayers(WidgetTester tester, List<String> names) async {
    for (final name in names) {
      await tester.tap(find.text(name).first);
      await tester.pumpAndSettle();
    }
  }

  Future<void> startGame(WidgetTester tester, List<String> names) async {
    await openSetup(tester);
    await selectPlayers(tester, names);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  }

  List<String> displayedOrder(WidgetTester tester, List<String> names) {
    return [...names]..sort(
        (left, right) => tester
            .getTopLeft(find.text(left).first)
            .dy
            .compareTo(tester.getTopLeft(find.text(right).first).dy),
      );
  }

  Future<void> dragPlayer(WidgetTester tester, String name, double dy) async {
    final gesture = await tester.startGesture(
      tester.getCenter(find.text(name).first),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    for (var step = 0; step < 4; step++) {
      await gesture.moveBy(Offset(0, dy / 4));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await gesture.up();
    await tester.pumpAndSettle();
  }

  Future<void> chooseSort(WidgetTester tester, String label) async {
    await tester.tap(find.byTooltip('Sort players'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  const players = ['Mina', 'Avery', 'Jules'];

  testWidgets('name sort orders players and play order restores them', (
    tester,
  ) async {
    await startGame(tester, players);

    expect(displayedOrder(tester, players), ['Mina', 'Avery', 'Jules']);

    await chooseSort(tester, 'Name');
    expect(displayedOrder(tester, players), ['Avery', 'Jules', 'Mina']);

    await chooseSort(tester, 'Play order');
    expect(displayedOrder(tester, players), ['Mina', 'Avery', 'Jules']);
  });

  testWidgets('long press drag reorders players only in play order', (
    tester,
  ) async {
    await startGame(tester, players);

    await dragPlayer(tester, 'Mina', 300);
    expect(displayedOrder(tester, players), ['Avery', 'Jules', 'Mina']);

    await dragPlayer(tester, 'Jules', -300);
    expect(displayedOrder(tester, players), ['Jules', 'Avery', 'Mina']);

    // Name sort shows Avery, Jules, Mina; a blocked drag leaves play order alone.
    await chooseSort(tester, 'Name');
    await dragPlayer(tester, 'Avery', 300);
    await chooseSort(tester, 'Play order');
    expect(displayedOrder(tester, players), ['Jules', 'Avery', 'Mina']);
  });

  testWidgets('setup list can be reordered before starting', (tester) async {
    await openSetup(tester);
    await selectPlayers(tester, players);

    await dragPlayer(tester, 'Mina', 200);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(displayedOrder(tester, players), ['Avery', 'Jules', 'Mina']);
  });

  testWidgets('score sort uses earlier rounds and holds still mid-round', (
    tester,
  ) async {
    await startGame(tester, players);

    // Jules (third) scores in round 1.
    await tester.tap(find.byTooltip('Increase score').at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next Round >>'));
    await tester.pumpAndSettle();

    await chooseSort(tester, 'Score');
    expect(displayedOrder(tester, players), ['Jules', 'Mina', 'Avery']);

    // Avery (now last) pulls ahead this round, but rows don't move yet.
    await tester.tap(find.byTooltip('Increase score').at(2));
    await tester.tap(find.byTooltip('Increase score').at(2));
    await tester.pumpAndSettle();
    expect(displayedOrder(tester, players), ['Jules', 'Mina', 'Avery']);

    await tester.tap(find.text('Next Round >>'));
    await tester.pumpAndSettle();
    expect(displayedOrder(tester, players), ['Avery', 'Jules', 'Mina']);
  });

  testWidgets('picking score sort mid-round sorts by the current totals', (
    tester,
  ) async {
    await startGame(tester, players);

    // Round 1: Avery (second) scores 2.
    await tester.tap(find.byTooltip('Increase score').at(1));
    await tester.pump();
    await tester.tap(find.byTooltip('Increase score').at(1));
    await tester.pump();
    await tester.pumpAndSettle();

    await chooseSort(tester, 'Score');
    expect(displayedOrder(tester, players), ['Avery', 'Mina', 'Jules']);

    // Jules (last) scores 3 in the same round; rows hold still.
    for (var tap = 0; tap < 3; tap++) {
      await tester.tap(find.byTooltip('Increase score').at(2));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(displayedOrder(tester, players), ['Avery', 'Mina', 'Jules']);

    // Picking Score again re-sorts by the latest totals.
    await chooseSort(tester, 'Name');
    await chooseSort(tester, 'Score');
    expect(displayedOrder(tester, players), ['Jules', 'Avery', 'Mina']);
  });
}
