import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/application/models/scoring/value_picker_definition.dart';
import 'package:scoard_game/ui/score_input/numeric_value_picker.dart';
import 'package:scoard_game/ui/score_input/score_entry_mode.dart';
import 'package:scoard_game/ui/score_input/score_value_edit_action.dart';
import 'package:scoard_game/ui/score_input/score_value_edit_request.dart';

import '../../support/test_templates.dart';

void main() {
  final skyjoCards =
      loadTestTemplateCatalog().byId('skyjo').scoreFields.single.valuePickers;

  Future<void> openSheet(
    WidgetTester tester, {
    required ScoreEntryMemory memory,
    List<ValuePickerDefinition>? valuePickers,
    ValueChanged<ScoreValueEditRequest?>? onClosed,
    Size logicalSize = const Size(360, 800),
    double statusBarHeight = 0,
  }) async {
    tester.view.physicalSize = logicalSize * 3;
    tester.view.devicePixelRatio = 3;
    tester.view.padding = FakeViewPadding(top: statusBarHeight * 3);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final result = await showNumericValuePicker(
                  context,
                  title: 'Avery',
                  currentValue: 10,
                  allowReplace: true,
                  allowAdjust: true,
                  entryMemory: memory,
                  valuePickers: valuePickers ?? skyjoCards,
                );
                onClosed?.call(result);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  // Tiles in the picker grid, as opposed to the smaller picked tiles above.
  Finder tile(String value) => find
      .ancestor(of: find.text(value), matching: find.byType(InkWell))
      .last;

  testWidgets('a template picker is the starting mode and adds up taps', (
    tester,
  ) async {
    final memory = ScoreEntryMemory();
    ScoreValueEditRequest? request;
    await openSheet(tester, memory: memory, onClosed: (r) => request = r);

    expect(find.text('Cards'), findsOneWidget);

    await tester.tap(tile('12'));
    await tester.pump();
    await tester.tap(tile('5'));
    await tester.pump();
    await tester.tap(tile('-2'));
    await tester.pump();
    await tester.tap(tile('5'));
    await tester.pump();

    expect(find.text('= 20'), findsOneWidget);
    expect(find.text('×2'), findsOneWidget);
    expect(find.text('Replace -> 20'), findsOneWidget);
    expect(find.text('Adjust -> 30'), findsOneWidget);

    // Take back the 12, which is the first picked tile.
    await tester.tap(find.byTooltip('Remove 12'));
    await tester.pump();

    expect(find.text('= 8'), findsOneWidget);

    await tester.tap(find.text('Replace -> 8'));
    await tester.pumpAndSettle();

    expect(request?.action, ScoreValueEditAction.replace);
    expect(request?.value, 8);
    expect(memory.valuePickerId, isNull);
  });

  testWidgets('switching modes is remembered for the game', (tester) async {
    final memory = ScoreEntryMemory();
    await openSheet(tester, memory: memory);

    await tester.tap(find.byTooltip('Calculator'));
    await tester.pumpAndSettle();

    expect(memory.mode, ScoreEntryMode.calculator);
    expect(memory.valuePickerId, isNull);

    await tester.tap(find.byTooltip('Cards'));
    await tester.pumpAndSettle();

    expect(memory.valuePickerId, 'cards');
    expect(memory.mode, isNull);
  });

  testWidgets('a remembered built-in mode wins over the template picker', (
    tester,
  ) async {
    await openSheet(
      tester,
      memory: ScoreEntryMemory()..mode = ScoreEntryMode.calculator,
    );

    expect(find.text('Score value'), findsOneWidget);
    expect(find.text('Cards'), findsNothing);
  });

  testWidgets('submitting with nothing tapped asks for a value', (tester) async {
    await openSheet(tester, memory: ScoreEntryMemory());

    await tester.tap(find.text('Replace'));
    await tester.pumpAndSettle();

    expect(find.text('Tap at least one value.'), findsOneWidget);
  });

  testWidgets('fields without a picker start in the calculator', (tester) async {
    await openSheet(tester, memory: ScoreEntryMemory(), valuePickers: const []);

    expect(find.text('Score value'), findsOneWidget);
    expect(find.byTooltip('Cards'), findsNothing);
  });

  testWidgets('the Skyjo cards fit a small phone without scrolling', (
    tester,
  ) async {
    await openSheet(
      tester,
      memory: ScoreEntryMemory(),
      logicalSize: const Size(360, 640),
      statusBarHeight: 24,
    );

    // Pick a full twelve-card grid's worth of cards.
    for (var card = 0; card < 12; card++) {
      await tester.tap(tile('${card % 13 - 1}'));
      await tester.pump();
    }

    final sheetScroll = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(SingleChildScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(sheetScroll.position.maxScrollExtent, 0);
    expect(find.text('Cancel').hitTestable(), findsOneWidget);
  });

  group('Flip 7 cards', () {
    final flip7Cards =
        loadTestTemplateCatalog().byId('flip-7').scoreFields.single.valuePickers;

    testWidgets('×2 doubles the number cards as they are tapped', (
      tester,
    ) async {
      ScoreValueEditRequest? request;
      await openSheet(
        tester,
        memory: ScoreEntryMemory(),
        valuePickers: flip7Cards,
        onClosed: (r) => request = r,
      );

      for (final card in ['8', '6', '3']) {
        await tester.tap(tile(card));
        await tester.pump();
      }
      expect(find.text('= 17'), findsOneWidget);

      await tester.tap(tile('×2'));
      await tester.pump();
      expect(find.text('= 34'), findsOneWidget);

      await tester.tap(tile('+4'));
      await tester.pump();
      expect(find.text('= 38'), findsOneWidget);

      // Taking back the ×2 undoes the doubling.
      await tester.tap(find.byTooltip('Remove ×2'));
      await tester.pump();
      expect(find.text('= 21'), findsOneWidget);

      await tester.tap(tile('×2'));
      await tester.pump();
      await tester.tap(find.text('Replace -> 38'));
      await tester.pumpAndSettle();

      expect(request?.value, 38);
    });

    testWidgets('Bust makes the round 0', (tester) async {
      ScoreValueEditRequest? request;
      await openSheet(
        tester,
        memory: ScoreEntryMemory(),
        valuePickers: flip7Cards,
        onClosed: (r) => request = r,
      );

      await tester.tap(tile('9'));
      await tester.pump();
      await tester.tap(tile('Bust'));
      await tester.pump();

      expect(find.text('= 0'), findsOneWidget);

      await tester.tap(find.text('Replace -> 0'));
      await tester.pumpAndSettle();

      expect(request?.value, 0);
    });

    testWidgets('every Flip 7 tile fits a small phone without scrolling', (
      tester,
    ) async {
      await openSheet(
        tester,
        memory: ScoreEntryMemory(),
        valuePickers: flip7Cards,
        logicalSize: const Size(360, 640),
        statusBarHeight: 24,
      );

      // A full hand: seven number cards, two modifiers, and ×2.
      for (final card in ['0', '2', '5', '7', '9', '11', '12', '+4', '+10', '×2']) {
        await tester.tap(tile(card));
        await tester.pump();
      }

      final sheetScroll = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byType(SingleChildScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(sheetScroll.position.maxScrollExtent, 0);
      expect(find.text('Cancel').hitTestable(), findsOneWidget);
    });
  });
}
