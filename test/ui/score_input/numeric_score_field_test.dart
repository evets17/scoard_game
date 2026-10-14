import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/application/models/scoring/entered_line_definition.dart';
import 'package:scoard_game/application/models/scoring/score_input_kind.dart';
import 'package:scoard_game/ui/score_input/numeric_score_field.dart';

void main() {
  testWidgets('score control keeps a stable width up to its minimum display digits', (
    tester,
  ) async {
    final controller = TextEditingController(text: '9');

    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: NumericScoreField(
            label: 'Avery',
            controller: controller,
            lineDefinition: const EnteredLineDefinition(
              id: 'score',
              label: 'Score',
              inputKind: ScoreInputKind.integer,
              isEntered: true,
              contributesToFinalResult: true,
              minimumDisplayDigits: 3,
            ),
          ),
        ),
      ),
    );

    final oneDigitWidth = tester.getSize(find.byType(InkWell)).width;

    controller.text = '99';
    await tester.pump();
    final twoDigitWidth = tester.getSize(find.byType(InkWell)).width;

    controller.text = '999';
    await tester.pump();
    final threeDigitWidth = tester.getSize(find.byType(InkWell)).width;

    expect(oneDigitWidth, threeDigitWidth);
    expect(twoDigitWidth, threeDigitWidth);
  });

  testWidgets('score control grows after exceeding its minimum display digits', (
    tester,
  ) async {
    final controller = TextEditingController(text: '99');

    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: NumericScoreField(
            label: 'Avery',
            controller: controller,
            lineDefinition: const EnteredLineDefinition(
              id: 'score',
              label: 'Score',
              inputKind: ScoreInputKind.integer,
              isEntered: true,
              contributesToFinalResult: true,
              minimumDisplayDigits: 2,
            ),
          ),
        ),
      ),
    );

    final twoDigitWidth = tester.getSize(find.byType(InkWell)).width;

    controller.text = '100';
    await tester.pump();
    final threeDigitWidth = tester.getSize(find.byType(InkWell)).width;

    expect(threeDigitWidth, greaterThan(twoDigitWidth));
  });
}