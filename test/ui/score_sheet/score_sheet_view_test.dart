import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/bootstrap/app_bootstrap.dart';
import 'package:scoard_game/bootstrap/app_environment.dart';
import 'package:scoard_game/ui/round_score/round_score_flow_screen.dart';
import 'package:scoard_game/ui/score_input/numeric_score_field.dart';
import 'package:scoard_game/ui/score_sheet/score_sheet_grid.dart';

import '../../support/test_templates.dart';

void main() {
  Future<AppEnvironment> startGame(
    WidgetTester tester, {
    String templateId = 'round-score-basic',
    List<String> players = const ['Avery', 'Jules'],
  }) async {
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
          preset: environment.templateCatalog.byId(templateId),
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

    for (final name in players) {
      await tester.tap(find.text(name).first);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    return environment;
  }

  Finder rowFor(String name) =>
      find.ancestor(of: find.text(name), matching: find.byType(Card)).first;

  Future<void> add(WidgetTester tester, String name, int times) async {
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

  Finder inSheet(String text) => find.descendant(
        of: find.byType(ScoreSheetGrid),
        matching: find.text(text),
      );

  testWidgets('the sheet shows every round and selects one when tapped', (
    tester,
  ) async {
    final environment = await startGame(tester);

    // Round 1: Avery 3, Jules 1. Round 2: Avery 2, Jules 5. Round 3 open.
    await add(tester, 'Avery', 3);
    await add(tester, 'Jules', 1);
    await tester.tap(find.text('Next Round >>'));
    await tester.pumpAndSettle();
    await add(tester, 'Avery', 2);
    await add(tester, 'Jules', 5);
    await tester.tap(find.text('Next Round >>'));
    await tester.pumpAndSettle();
    expect(find.text('Round 3'), findsOneWidget);

    await tester.tap(find.byTooltip('Show sheet'));
    await tester.pumpAndSettle();

    expect(find.byType(ScoreSheetGrid), findsOneWidget);
    expect(find.byType(NumericScoreField), findsNothing);
    final grid = tester.widget<ScoreSheetGrid>(find.byType(ScoreSheetGrid));
    expect(grid.rows.map((row) => row.label), ['1', '2', '3']);
    expect(grid.rows.map((row) => row.selected), [false, false, true]);
    expect(
      [for (final row in grid.rows) row.cells.map((cell) => cell.score)],
      [
        [3, 1],
        [2, 5],
        [null, null],
      ],
    );
    expect(grid.players.map((player) => player.total), [5, 6]);

    // Tapping round 1 selects it, as Previous Round would (tapping the
    // round label, not Jules's score of 1). Like Previous Round, leaving
    // the empty round 3 doesn't keep it.
    await tester.tap(inSheet('1').first);
    await tester.pumpAndSettle();
    expect(find.text('Round 1'), findsOneWidget);
    expect(
      tester
          .widget<ScoreSheetGrid>(find.byType(ScoreSheetGrid))
          .rows
          .map((row) => row.selected),
      [true, false],
    );

    // The game remembers the sheet view.
    final summary = (await environment.sessionRepository.loadActiveSessions(
      limit: 10,
    ))
        .firstWhere((summary) => summary.gameName == 'Round Score');
    final saved =
        await environment.loadRoundScoreActiveSession(sessionId: summary.id);
    expect(saved!.showSheet, isTrue);

    await tester.tap(find.byTooltip('Show player cards'));
    await tester.pumpAndSettle();
    expect(find.byType(ScoreSheetGrid), findsNothing);
    expect(find.byType(NumericScoreField), findsNWidgets(2));
    expect(find.text('Round 1'), findsOneWidget);
  });

  Future<void> tapTiles(WidgetTester tester, List<String> tiles) async {
    for (final tile in tiles) {
      await tester.tap(
        find.ancestor(of: find.text(tile), matching: find.byType(InkWell)).last,
      );
      await tester.pump();
    }
  }

  /// Enters a Flip 7 round with Next: Avery, then Jules, then Mina.
  Future<void> enterRoundWithNext(
    WidgetTester tester,
    List<String> tiles,
  ) async {
    await tester.tap(
      find.descendant(of: rowFor('Avery'), matching: find.text('–')).first,
    );
    await tester.pumpAndSettle();
    await tapTiles(tester, [tiles[0]]);
    await tester.tap(find.text('Next: Jules'));
    await tester.pumpAndSettle();
    await tapTiles(tester, [tiles[1]]);
    await tester.tap(find.text('Next: Mina'));
    await tester.pumpAndSettle();
    await tapTiles(tester, [tiles[2]]);
    // Mina is last in play order, so there is no Next.
    expect(find.textContaining('Next:'), findsNothing);
    await tester.tap(find.text('Replace -> ${tiles[2]}'));
    await tester.pumpAndSettle();
  }

  testWidgets('Next moves to the next player in play order', (tester) async {
    await startGame(
      tester,
      templateId: 'flip-7',
      players: const ['Avery', 'Jules', 'Mina'],
    );

    await enterRoundWithNext(tester, ['9', '5', '3']);

    for (final (name, score) in [('Avery', '9'), ('Jules', '5'), ('Mina', '3')]) {
      expect(
        find.descendant(of: rowFor(name), matching: find.text(score)),
        findsWidgets,
      );
    }
  });

  testWidgets('a past round is corrected by tapping its cell', (tester) async {
    await startGame(
      tester,
      templateId: 'flip-7',
      players: const ['Avery', 'Jules', 'Mina'],
    );
    await enterRoundWithNext(tester, ['9', '5', '3']);
    await tester.tap(find.text('Next Round >>'));
    await tester.pumpAndSettle();
    await enterRoundWithNext(tester, ['1', '2', '4']);
    await tester.tap(find.byTooltip('Show sheet'));
    await tester.pumpAndSettle();

    // Jules's round 1 cell opens with the 5 tile still picked; add a 7.
    await tester.tap(inSheet('5'));
    await tester.pumpAndSettle();
    expect(find.text('Replace -> 5'), findsOneWidget);
    await tapTiles(tester, ['7']);
    await tester.tap(find.text('Replace -> 12'));
    await tester.pumpAndSettle();

    expect(find.text('Round 1'), findsOneWidget);
    final grid = tester.widget<ScoreSheetGrid>(find.byType(ScoreSheetGrid));
    expect(grid.rows.first.cells.map((cell) => cell.score), [9, 12, 3]);
    expect(grid.players.map((player) => player.total), [10, 14, 7]);
  });

  testWidgets('cells show score labels and headers show badges', (
    tester,
  ) async {
    await startGame(
      tester,
      templateId: 'flip-7',
      players: const ['Avery', 'Jules', 'Mina'],
    );

    // Avery busts in round 1.
    await tester.tap(
      find.descendant(of: rowFor('Avery'), matching: find.text('–')).first,
    );
    await tester.pumpAndSettle();
    for (final tile in ['9', 'Bust']) {
      await tester.tap(
        find.ancestor(of: find.text(tile), matching: find.byType(InkWell)).last,
      );
      await tester.pump();
    }
    await tester.tap(find.text('Replace -> 0'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Show sheet'));
    await tester.pumpAndSettle();

    expect(inSheet('Bust'), findsOneWidget);
    // Round 1's first player is Avery, shown by the name.
    final grid = tester.widget<ScoreSheetGrid>(find.byType(ScoreSheetGrid));
    expect(
      {
        for (final player in grid.players)
          player.name: [for (final badge in player.badges) badge.text],
      },
      {
        'Avery': ['1st'],
        'Jules': <String>[],
        'Mina': <String>[],
      },
    );
    expect(inSheet('1st'), findsOneWidget);
  });
}
