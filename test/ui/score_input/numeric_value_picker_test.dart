import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/ui/score_input/numeric_value_picker.dart';
import 'package:scoard_game/ui/score_input/score_value_edit_action.dart';
import 'package:scoard_game/ui/score_input/score_value_edit_request.dart';

void main() {
  Future<void> openPicker(
    WidgetTester tester, {
    required ValueChanged<ScoreValueEditRequest?> onClosed,
  }) async {
    // A typical phone: 360 × 800 logical pixels.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                onClosed(
                  await showNumericValuePicker(
                    context,
                    title: 'Avery',
                    currentValue: 10,
                    allowReplace: true,
                    allowAdjust: true,
                  ),
                );
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

  Future<void> press(WidgetTester tester, List<String> keys) async {
    for (final key in keys) {
      await tester.tap(find.widgetWithText(FilledButton, key));
      await tester.pump();
    }
  }

  testWidgets('tallies a score and replaces with the result', (tester) async {
    ScoreValueEditRequest? request;
    await openPicker(tester, onClosed: (result) => request = result);

    await press(tester, ['3', '+', '4', '+', '5', '×', '2']);

    expect(find.text('3 + 4 + 5 × 2'), findsOneWidget);
    expect(find.text('= 24'), findsOneWidget);
    expect(find.text('Replace -> 24'), findsOneWidget);
    expect(find.text('Adjust -> 34'), findsOneWidget);

    await tester.tap(find.text('Replace -> 24'));
    await tester.pumpAndSettle();

    expect(request?.action, ScoreValueEditAction.replace);
    expect(request?.value, 24);
  });

  testWidgets('a plain number still adjusts the current score', (
    tester,
  ) async {
    ScoreValueEditRequest? request;
    await openPicker(tester, onClosed: (result) => request = result);

    await press(tester, ['7']);

    expect(find.text('Adjust -> 17'), findsOneWidget);

    await tester.tap(find.text('Adjust -> 17'));
    await tester.pumpAndSettle();

    expect(request?.action, ScoreValueEditAction.add);
    expect(request?.value, 7);
  });

  testWidgets('calculation line appears only after an operator, keys stay put', (
    tester,
  ) async {
    await openPicker(tester, onClosed: (_) {});

    final display = find.ancestor(
      of: find.text('Score value'),
      matching: find.byType(Container),
    );
    await press(tester, ['5']);
    await tester.pumpAndSettle();
    final singleLineHeight = tester.getSize(display.first).height;
    final keyPosition = tester.getTopLeft(find.widgetWithText(FilledButton, '7'));

    await press(tester, ['+']);
    await tester.pumpAndSettle();

    expect(find.text('5 +'), findsOneWidget);
    expect(tester.getSize(display.first).height, greaterThan(singleLineHeight));
    expect(
      tester.getTopLeft(find.widgetWithText(FilledButton, '7')),
      keyPosition,
    );
  });

  testWidgets('division by zero blocks submitting', (tester) async {
    var closed = false;
    await openPicker(tester, onClosed: (_) => closed = true);

    await press(tester, ['8', '÷', '0']);

    expect(find.text('Can\'t divide by zero.'), findsOneWidget);

    await tester.tap(find.text('Replace'));
    await tester.pumpAndSettle();

    expect(closed, isFalse);
    expect(find.text('Can\'t divide by zero.'), findsOneWidget);
  });
}
