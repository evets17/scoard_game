import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/ui/score_input/numeric_value_picker.dart';
import 'package:scoard_game/ui/score_input/quick_pick_grid.dart';
import 'package:scoard_game/ui/score_input/score_entry_mode.dart';
import 'package:scoard_game/ui/score_input/score_value_edit_action.dart';
import 'package:scoard_game/ui/score_input/score_value_edit_request.dart';

void main() {
  Future<void> openPicker(
    WidgetTester tester, {
    required ScoreEntryMemory memory,
    ValueChanged<ScoreValueEditRequest?>? onClosed,
    Size logicalSize = const Size(360, 800),
    double statusBarHeight = 0,
    (int, int)? range,
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
                  quickPickRange: range,
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

  Finder key(String label) => find.widgetWithText(FilledButton, label);

  bool isOnScreen(WidgetTester tester, String label) {
    final finder = key(label);
    if (finder.evaluate().isEmpty) {
      return false;
    }
    final rect = tester.getRect(finder);
    final screen = Offset.zero & tester.view.physicalSize / 3;
    return screen.contains(rect.topLeft) && screen.contains(rect.bottomRight);
  }

  test('columns run −1…−10, then 0–9 up to 90–99', () {
    expect(QuickPickGrid.valueAt(column: 0, row: 0), -1);
    expect(QuickPickGrid.valueAt(column: 0, row: 9), -10);
    expect(QuickPickGrid.valueAt(column: 1, row: 0), 0);
    expect(QuickPickGrid.valueAt(column: 3, row: 7), 27);
    expect(QuickPickGrid.valueAt(column: 10, row: 9), 99);
    expect(QuickPickGrid.columnOf(-10), 0);
    expect(QuickPickGrid.columnOf(9), 1);
    expect(QuickPickGrid.columnOf(45), 5);
  });

  testWidgets('quick pick selects a number and adjusts with it', (
    tester,
  ) async {
    final memory = ScoreEntryMemory();
    ScoreValueEditRequest? request;
    await openPicker(tester, memory: memory, onClosed: (r) => request = r);

    await tester.tap(find.byTooltip('Quick pick'));
    await tester.pumpAndSettle();
    await tester.tap(key('7'));
    await tester.pump();

    expect(find.text('Replace -> 7'), findsOneWidget);
    expect(find.text('Adjust -> 17'), findsOneWidget);

    await tester.tap(find.text('Adjust -> 17'));
    await tester.pumpAndSettle();

    expect(request?.action, ScoreValueEditAction.add);
    expect(request?.value, 7);
    expect(memory.mode, ScoreEntryMode.quickPick);
    expect(memory.quickPickColumn, 1);
  });

  testWidgets('tapping the selected number again clears it', (tester) async {
    await openPicker(
      tester,
      memory: ScoreEntryMemory()..mode = ScoreEntryMode.quickPick,
    );

    await tester.tap(key('3'));
    await tester.pump();
    expect(find.text('Replace -> 3'), findsOneWidget);

    await tester.tap(key('3'));
    await tester.pump();
    expect(find.text('Replace'), findsOneWidget);
  });

  testWidgets('reopens in quick pick centered on the last column', (
    tester,
  ) async {
    final memory = ScoreEntryMemory()
      ..mode = ScoreEntryMode.quickPick
      ..quickPickColumn = QuickPickGrid.columnOf(45);
    await openPicker(tester, memory: memory);

    expect(find.byType(QuickPickGrid), findsOneWidget);
    expect(isOnScreen(tester, '45'), isTrue);
    expect(isOnScreen(tester, '-1'), isFalse);
  });

  testWidgets('swiping reaches the higher columns', (tester) async {
    await openPicker(
      tester,
      memory: ScoreEntryMemory()..mode = ScoreEntryMode.quickPick,
    );

    expect(isOnScreen(tester, '95'), isFalse);

    await tester.fling(find.byType(QuickPickGrid), const Offset(-600, 0), 2000);
    await tester.pumpAndSettle();

    expect(isOnScreen(tester, '95'), isTrue);
  });

  for (final size in [const Size(360, 800), const Size(360, 640)]) {
    testWidgets('quick pick fits without scrolling on a ${size.height.toInt()}px tall phone', (
      tester,
    ) async {
      await openPicker(
        tester,
        memory: ScoreEntryMemory()..mode = ScoreEntryMode.quickPick,
        logicalSize: size,
        statusBarHeight: 24,
      );

      final sheetScroll = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byType(SingleChildScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );

      expect(sheetScroll.position.maxScrollExtent, 0);
      expect(tester.getTopLeft(find.text('Avery')).dy, greaterThanOrEqualTo(24));
      expect(isOnScreen(tester, '9'), isTrue);
      expect(find.text('Cancel').hitTestable(), findsOneWidget);
    });
  }

  testWidgets('a range shows only its numbers, and the calculator takes any', (
    tester,
  ) async {
    ScoreValueEditRequest? request;
    await openPicker(
      tester,
      memory: ScoreEntryMemory()..mode = ScoreEntryMode.quickPick,
      range: (0, 12),
      onClosed: (r) => request = r,
    );

    expect(isOnScreen(tester, '0'), isTrue);
    expect(isOnScreen(tester, '12'), isTrue);
    expect(key('13'), findsNothing);
    expect(key('-1'), findsNothing);

    await tester.tap(key('12'));
    await tester.pump();
    expect(find.text('Replace -> 12'), findsOneWidget);

    // Not a rule: the calculator still takes a number outside the range.
    await tester.tap(find.byTooltip('Calculator'));
    await tester.pumpAndSettle();
    for (final digit in ['4', '5']) {
      await tester.tap(key(digit));
      await tester.pump();
    }
    await tester.tap(find.text('Replace -> 45'));
    await tester.pumpAndSettle();
    expect(request?.value, 45);
  });

  testWidgets('a 0–30 range fits on a 640px tall phone in six rows', (
    tester,
  ) async {
    await openPicker(
      tester,
      memory: ScoreEntryMemory()..mode = ScoreEntryMode.quickPick,
      range: (0, 30),
      logicalSize: const Size(360, 640),
      statusBarHeight: 24,
    );

    expect(isOnScreen(tester, '30'), isTrue);
    final rows = {
      for (final value in [0, 6, 12, 18, 24, 30])
        tester.getTopLeft(key('$value')).dy,
    };
    expect(rows, hasLength(6));
    expect(tester.getTopLeft(key('5')).dy, tester.getTopLeft(key('0')).dy);
    expect(find.text('Cancel').hitTestable(), findsOneWidget);
  });
}
