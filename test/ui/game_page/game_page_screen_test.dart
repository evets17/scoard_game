import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_answer.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_behavior.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_definition.dart';
import 'package:scoard_game/application/models/scoring/entered_line_definition.dart';
import 'package:scoard_game/application/models/scoring/score_input_kind.dart';
import 'package:scoard_game/application/models/scoring/scoring_model.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/application/models/scoring/winner_rule.dart';
import 'package:scoard_game/ui/game_page/game_page_screen.dart';

ScoringPreset preset({
  String? subtitle,
  String? source,
  int minimumPlayers = 2,
  int? maximumPlayers,
  List<PresetPromptDefinition> prompts = const [],
}) {
  return ScoringPreset(
    id: 'test-game',
    displayName: 'Test Game',
    subtitle: subtitle,
    description: 'A longer explanation of how this game is scored.',
    source: source,
    scoringModel: ScoringModel.rounds,
    minimumPlayers: minimumPlayers,
    maximumPlayers: maximumPlayers,
    winnerRule: WinnerRule.highestScoreWins,
    promptDefinitions: prompts,
    enteredLines: const [
      EnteredLineDefinition(
        id: 'score',
        label: 'Score',
        inputKind: ScoreInputKind.integer,
        isEntered: true,
        contributesToFinalResult: true,
      ),
    ],
  );
}

void main() {
  Future<List<PresetPromptAnswer>?> Function() pumpPage(
    WidgetTester tester,
    ScoringPreset preset, {
    Future<bool> Function(Uri uri)? openLink,
  }) {
    List<PresetPromptAnswer>? started;
    return () async {
      await tester.pumpWidget(
        MaterialApp(
          home: GamePageScreen(
            preset: preset,
            onStart: (answers) => started = answers,
            openLink: openLink ?? (_) async => true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      return started;
    };
  }

  test('player counts read naturally', () {
    expect(playerCountLabel(preset(maximumPlayers: 8)), '2–8 players');
    expect(playerCountLabel(preset()), '2+ players');
    expect(playerCountLabel(preset(maximumPlayers: 2)), '2 players');
    expect(
      playerCountLabel(preset(minimumPlayers: 1, maximumPlayers: 1)),
      '1 player',
    );
  });

  testWidgets('a game without options shows its details and starts', (
    tester,
  ) async {
    List<PresetPromptAnswer>? started;
    await tester.pumpWidget(
      MaterialApp(
        home: GamePageScreen(
          preset: preset(
            subtitle: 'Alternate rules',
            maximumPlayers: 8,
            source: 'Rulebook, scoring section',
          ),
          onStart: (answers) => started = answers,
        ),
      ),
    );

    expect(find.text('Test Game'), findsOneWidget);
    expect(find.text('Alternate rules'), findsOneWidget);
    expect(
      find.text('A longer explanation of how this game is scored.'),
      findsOneWidget,
    );
    expect(find.text('2–8 players'), findsOneWidget);
    expect(find.text('Scoring rules: Rulebook, scoring section'), findsOneWidget);
    expect(find.text('Options'), findsNothing);

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    expect(started, isEmpty);
  });

  testWidgets('options are shown and their answers passed on Start', (
    tester,
  ) async {
    List<PresetPromptAnswer>? started;
    await tester.pumpWidget(
      MaterialApp(
        home: GamePageScreen(
          preset: preset(
            prompts: const [
              PresetPromptDefinition.boolean(
                id: 'low-score-wins',
                label: 'Low Score Wins',
                promptText: 'Use the lowest score as the winner.',
              ),
              PresetPromptDefinition.integer(
                id: 'play-until',
                label: 'Winning Score',
                promptText: 'What score are you playing to?',
                defaultIntegerValue: 100,
              ),
            ],
          ),
          onStart: (answers) => started = answers,
        ),
      ),
    );

    expect(find.text('Options'), findsOneWidget);
    expect(find.text('Low Score Wins'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '250');
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    expect(started![0].booleanValue, isTrue);
    expect(started![1].integerValue, 250);
  });

  testWidgets('a web address source opens as a link', (tester) async {
    final opened = <Uri>[];
    await pumpPage(
      tester,
      preset(source: 'https://example.com/rules'),
      openLink: (uri) async {
        opened.add(uri);
        return true;
      },
    )();

    expect(find.text('Scoring rules'), findsOneWidget);

    await tester.tap(find.text('Scoring rules'));
    await tester.pumpAndSettle();

    expect(opened, [Uri.parse('https://example.com/rules')]);
  });

  testWidgets('a link that cannot open says so', (tester) async {
    await pumpPage(
      tester,
      preset(source: 'https://example.com/rules'),
      openLink: (_) async => false,
    )();

    await tester.tap(find.text('Scoring rules'));
    await tester.pumpAndSettle();

    expect(find.text('The rules link could not be opened.'), findsOneWidget);
  });

  testWidgets('a game name starts as the default and offers recent names', (
    tester,
  ) async {
    List<PresetPromptAnswer>? started;
    await tester.pumpWidget(
      MaterialApp(
        home: GamePageScreen(
          preset: preset(
            prompts: const [
              PresetPromptDefinition.text(
                id: 'game-name',
                label: 'Game',
                behavior: PresetPromptBehavior.gameName,
                defaultTextValue: 'Round Score',
              ),
            ],
          ),
          loadRecentGameNames: () async => ['Catan', 'Round Score', 'Azul'],
          onStart: (answers) => started = answers,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final field = find.byType(TextField);
    expect(tester.widget<TextField>(field).controller!.text, 'Round Score');
    // The default is already in the field, so it is not offered again.
    expect(find.widgetWithText(ChoiceChip, 'Catan'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Azul'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Round Score'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Catan'));
    await tester.pump();
    expect(tester.widget<TextField>(field).controller!.text, 'Catan');

    await tester.tap(find.text('Start'));
    await tester.pump();
    expect(started!.single.textValue, 'Catan');

    // Typed in, it is trimmed.
    await tester.enterText(field, '  Ticket to Ride ');
    await tester.tap(find.text('Start'));
    await tester.pump();
    expect(started!.single.textValue, 'Ticket to Ride');
  });
}
