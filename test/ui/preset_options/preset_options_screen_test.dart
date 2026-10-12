import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_answer.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_definition.dart';
import 'package:scoard_game/application/models/scoring/score_field_definition.dart';
import 'package:scoard_game/application/models/scoring/score_input_kind.dart';
import 'package:scoard_game/application/models/scoring/scoring_model.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/application/models/scoring/winner_rule.dart';
import 'package:scoard_game/ui/preset_options/preset_options_screen.dart';

void main() {
  testWidgets('preset options screen renders dynamic boolean and integer prompts', (
    tester,
  ) async {
    List<PresetPromptAnswer>? submittedAnswers;

    await tester.pumpWidget(
      MaterialApp(
        home: PresetOptionsScreen(
          preset: ScoringPreset(
            id: 'test-preset',
            displayName: 'Test Preset',
            chooserDescription: 'Test description',
            scoringModel: ScoringModel.finalScore,
            minimumPlayers: 2,
            winnerRule: WinnerRule.highestScoreWins,
            promptDefinitions: const [
              PresetPromptDefinition.boolean(
                id: 'low-score-wins',
                label: 'Low Score Wins',
                promptText: 'Use the lowest score as the winner.',
                defaultBooleanValue: false,
              ),
              PresetPromptDefinition.integer(
                id: 'play-until',
                label: 'Winning Score',
                promptText: 'What score are you playing to?',
                defaultIntegerValue: 100,
              ),
            ],
            scoreFields: const [
              ScoreFieldDefinition(
                id: 'score',
                label: 'Score',
                inputKind: ScoreInputKind.integer,
                isEntered: true,
                contributesToFinalResult: true,
              ),
            ],
          ),
          onContinue: (answers) => submittedAnswers = answers,
        ),
      ),
    );

    expect(find.text('Low Score Wins'), findsOneWidget);
    expect(find.text('Winning Score'), findsNWidgets(2));

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '250');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(submittedAnswers, isNotNull);
    expect(submittedAnswers![0].booleanValue, true);
    expect(submittedAnswers![1].integerValue, 250);
  });
}