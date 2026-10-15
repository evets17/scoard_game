import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/application/services/templates/template_images.dart';
import 'package:scoard_game/bootstrap/app_bootstrap.dart';
import 'package:scoard_game/bootstrap/app_environment.dart';
import 'package:scoard_game/ui/quick_score/quick_score_flow_screen.dart';
import 'package:scoard_game/ui/score_input/numeric_score_field.dart';
import 'package:scoard_game/ui/score_sheet/score_sheet_grid.dart';

import '../../support/test_templates.dart';

/// The pictures bundled for template lines.
TemplateImages bundledImages() => TemplateImages(
      bundled: {
        for (final file in Directory(TemplateImages.bundledFolder)
            .listSync()
            .whereType<File>())
          file.uri.pathSegments.last,
      },
    );

void main() {
  Future<AppEnvironment> startCascadia(
    WidgetTester tester, {
    String templateId = 'cascadia',
  }) async {
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
          preset: environment.templateCatalog.byId(templateId),
          createPlayer: environment.createPlayer,
          renamePlayer: environment.renamePlayer,
          stayAwakeController: environment.stayAwakeController,
          rememberSetupPlayerGroup: environment.rememberSetupPlayerGroup,
          saveQuickScoreSession: environment.saveQuickScoreSession,
          saveQuickScoreActiveSession: environment.saveQuickScoreActiveSession,
          deleteActiveSession: environment.deleteActiveSession,
          templateImages: bundledImages(),
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

    // Lines show their pictures only; the bonus rows show picture and "+";
    // subtotals have no picture, so show their text.
    expect(rows.first.image, isNotNull);
    expect(rows.first.imageOnly, isTrue);
    final bonus = rows.firstWhere((row) => row.label == '+');
    expect(bonus.image, isNotNull);
    expect(bonus.imageOnly, isFalse);
    expect(rows[5].image, isNull);
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

  testWidgets('bonuses worked out show under their habitat, with no rows', (
    tester,
  ) async {
    await startCascadia(tester, templateId: 'cascadia-bonuses');

    final labels = grid(tester).rows.map((row) => row.label).toList();
    expect(labels, contains('Mountain'));
    expect(labels.where((label) => label.contains('bonus')), isEmpty);

    List<String?> subLabels(String label) => grid(tester)
        .rows
        .firstWhere((row) => row.label == label)
        .cells
        .map((cell) => cell.scoreSubLabel?.text)
        .toList();
    int mountainRow() =>
        grid(tester).rows.indexWhere((row) => row.label == 'Mountain');
    Future<void> enterMountain(int column, String digits) async {
      grid(tester).onCellTap!(mountainRow(), column);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Calculator'));
      await tester.pumpAndSettle();
      await press(tester, digits);
      await tester.tap(find.text('Replace -> $digits'));
      await tester.pumpAndSettle();
    }

    // Two players: the larger corridor scores 2.
    await enterMountain(0, '7');
    expect(subLabels('Mountain'), ['+2', null]);
    expect(rowScores(tester, 'HA'), [9, 0]);

    // A tie splits it, 1 each.
    await enterMountain(1, '7');
    expect(subLabels('Mountain'), ['+1', '+1']);
    expect(rowScores(tester, 'HA'), [8, 8]);
    expect(grid(tester).players.map((player) => player.total), [8, 8]);
  });
}
