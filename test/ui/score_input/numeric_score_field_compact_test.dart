import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/ui/score_input/numeric_score_field.dart';

import '../../support/test_templates.dart';

void main() {
  final lineDefinition = loadTestTemplateCatalog().byId('round-score-basic').enteredLines.first;

  Future<BuildContext> pumpRow(
    WidgetTester tester, {
    required bool compact,
    double textScale = 1,
  }) async {
    final controller = TextEditingController(text: '0');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: NumericScoreField(
                label: 'Avery',
                lineDefinition: lineDefinition,
                controller: controller,
                compact: compact,
                valueLabelMinimumDigits: 3,
                valueLabelBuilder: (value) => '$value',
              ),
            ),
          ),
        ),
      ),
    );

    return tester.element(find.byType(NumericScoreField));
  }

  // A Card's laid-out size already includes its outer margin.
  double renderedRowHeight(WidgetTester tester) =>
      tester.getSize(find.byType(Card)).height;

  for (final textScale in [1.0, 1.5]) {
    testWidgets('compact switch uses the real normal row height at $textScale× text', (
      tester,
    ) async {
      final context = await pumpRow(tester, compact: false, textScale: textScale);
      final rowHeight = renderedRowHeight(tester);

      bool compactAt(double availableHeight) => NumericScoreField.shouldUseCompact(
            context,
            rowCount: 4,
            availableHeight: availableHeight,
            lineDefinition: lineDefinition,
            hasValueLabel: true,
          );

      expect(compactAt(rowHeight * 4 + 1), isFalse);
      expect(compactAt(rowHeight * 4 - 1), isTrue);
    });
  }

  testWidgets('compact rows are shorter than normal rows', (tester) async {
    await pumpRow(tester, compact: false);
    final normalHeight = renderedRowHeight(tester);

    await pumpRow(tester, compact: true);
    final compactHeight = renderedRowHeight(tester);

    expect(compactHeight, lessThan(normalHeight));
  });
}
