import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/bootstrap/app_bootstrap.dart';
import 'package:scoard_game/bootstrap/app_environment.dart';
import 'package:scoard_game/ui/quick_score/quick_score_flow_screen.dart';
import 'package:scoard_game/ui/score_input/numeric_score_field.dart';
import 'package:scoard_game/ui/score_sheet/score_sheet_grid.dart';

import '../../support/test_templates.dart';

void main() {
  Future<AppEnvironment> startCascadia(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final environment = await AppBootstrap.initialize(
      templateCatalog: loadTestTemplateCatalog(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: QuickScoreFlowScreen(
          loadQuickScoreSetupModel: environment.loadQuickScoreSetupModel,
          preset: environment.templateCatalog.byId('cascadia'),
          createPlayer: environment.createPlayer,
          renamePlayer: environment.renamePlayer,
          stayAwakeController: environment.stayAwakeController,
          rememberSetupPlayerGroup: environment.rememberSetupPlayerGroup,
          saveQuickScoreSession: environment.saveQuickScoreSession,
          saveQuickScoreActiveSession: environment.saveQuickScoreActiveSession,
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
    return environment;
  }

  ScoreSheetGrid grid(WidgetTester tester) =>
      tester.widget<ScoreSheetGrid>(find.byType(ScoreSheetGrid));

  /// Values in the row labelled [label], by column.
  List<int?> rowScores(WidgetTester tester, String label) => grid(tester)
      .rows
      .firstWhere((row) => row.label == label)
      .cells
      .map((cell) => cell.score)
      .toList();

  Future<void> press(WidgetTester tester, String digits) async {
    for (final digit in digits.split('')) {
      await tester.tap(find.widgetWithText(FilledButton, digit));
      await tester.pump();
    }
  }

  Finder emptyCells() => find.descendant(
        of: find.byType(ScoreSheetGrid),
        matching: find.text('–'),
      );

  testWidgets('a sheet with several lines is scored line by line', (
    tester,
  ) async {
    final environment = await startCascadia(tester);

    // Several entered lines open on the sheet, not player cards.
    expect(find.byType(ScoreSheetGrid), findsOneWidget);
    expect(find.byType(NumericScoreField), findsNothing);
    // Rows follow the template: the wildlife lines, then their subtotal.
    final rows = grid(tester)
        .rows
        .where((row) => row.kind != ScoreSheetRowKind.heading)
        .toList();
    expect(
      rows.take(5).map((row) => row.label),
      ['Bear', 'Elk', 'Salmon', 'Hawk', 'Fox'],
    );
    expect(rows[5].style.bold, isTrue);
    expect(rows[5].editable, isFalse);
    // The score line is the totals row, under its own label.
    final preset = environment.templateCatalog.byId('cascadia');
    expect(
      grid(tester).totalLabel,
      preset.calculatedLines
          .firstWhere((line) => line.id == preset.scoreId)
          .label,
    );

    // Avery's Bear cell, then Next down Avery's column to Elk.
    await tester.tap(emptyCells().first);
    await tester.pumpAndSettle();
    expect(find.text('Avery · Bear'), findsOneWidget);
    await press(tester, '8');
    await tester.tap(find.text('Next: Elk'));
    await tester.pumpAndSettle();
    expect(find.text('Avery · Elk'), findsOneWidget);
    await press(tester, '6');
    await tester.tap(find.text('Replace -> 6'));
    await tester.pumpAndSettle();

    expect(rowScores(tester, 'Bear'), [8, null]);
    expect(rowScores(tester, 'Elk'), [6, null]);
    expect(
      grid(tester)
          .rows
          .firstWhere((row) => row.style.bold)
          .cells
          .map((cell) => cell.score),
      [14, 0],
    );
    expect(grid(tester).players.map((player) => player.total), [14, 0]);

    // Every line is saved with the game in progress, to come back on resume.
    final summary = (await environment.sessionRepository.loadActiveSessions(
      limit: 10,
    ))
        .firstWhere((summary) => summary.gameName == 'Cascadia');
    final saved =
        await environment.loadQuickScoreActiveSession(sessionId: summary.id);
    expect(
      saved!.participantValues.first.enteredValues,
      {'bear': 8, 'elk': 6},
    );

    // Resuming puts them back on the sheet.
    await tester.pumpWidget(
      MaterialApp(
        home: QuickScoreFlowScreen(
          key: const ValueKey('resumed'),
          loadQuickScoreSetupModel: environment.loadQuickScoreSetupModel,
          preset: environment.templateCatalog.byId('cascadia'),
          createPlayer: environment.createPlayer,
          renamePlayer: environment.renamePlayer,
          stayAwakeController: environment.stayAwakeController,
          rememberSetupPlayerGroup: environment.rememberSetupPlayerGroup,
          saveQuickScoreSession: environment.saveQuickScoreSession,
          saveQuickScoreActiveSession: environment.saveQuickScoreActiveSession,
          deleteActiveSession: environment.deleteActiveSession,
          initialActiveSession: saved,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(rowScores(tester, 'Bear'), [8, null]);
    expect(rowScores(tester, 'Elk'), [6, null]);

    // Jules has nothing entered yet, so the game can't be finished.
    await tester.tap(find.text('Game Over'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a score for every player.'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Jules's Bear cell is now the first empty one.
    await tester.tap(emptyCells().first);
    await tester.pumpAndSettle();
    expect(find.text('Jules · Bear'), findsOneWidget);
    await press(tester, '3');
    await tester.tap(find.text('Replace -> 3'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Game Over'));
    await tester.pumpAndSettle();
    expect(find.text('Result'), findsOneWidget);
    expect(find.text('14'), findsWidgets);
  });
}
