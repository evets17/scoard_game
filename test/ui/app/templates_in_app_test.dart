import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/bootstrap/app_bootstrap.dart';
import 'package:scoard_game/ui/app/scoard_game_app.dart';

import '../../support/test_templates.dart';

void main() {
  Future<void> openApp(WidgetTester tester) async {
    final environment = await AppBootstrap.initialize(
      templateCatalog: loadTestTemplateCatalog(),
    );
    await tester.pumpWidget(ScoardGameApp(environment: environment));
    await tester.pumpAndSettle();
  }

  testWidgets('Score a Game lists every template, and Skyjo plays as a game', (
    tester,
  ) async {
    await openApp(tester);

    await tester.tap(find.text('Score a Game'));
    await tester.pumpAndSettle();

    expect(find.text('Quick Score'), findsOneWidget);
    expect(find.text('Round Score'), findsOneWidget);
    expect(find.text('Skyjo'), findsOneWidget);

    await tester.tap(find.text('Skyjo'));
    await tester.pumpAndSettle();

    // Skyjo has no prompts, so it goes straight to choosing players.
    expect(find.text('Skyjo'), findsOneWidget);
    await tester.tap(find.text('Avery').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jules').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Round 1'), findsOneWidget);

    // Avery takes 3 points this round; lowest total wins in Skyjo.
    for (var tap = 0; tap < 3; tap++) {
      await tester.tap(find.byTooltip('Increase score').first);
      await tester.pump();
    }
    await tester.tap(find.text('Next Round >>'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Game Over'));
    await tester.pumpAndSettle();

    expect(find.text('Final Result'), findsOneWidget);
    expect(find.text('Winner'), findsOneWidget);
    // Jules appears as the winner and in the results list; Avery only in
    // the list.
    expect(find.text('Jules'), findsNWidgets(2));
    expect(find.text('Avery'), findsOneWidget);
  });

  testWidgets('a game saved with a built-in template still resumes', (
    tester,
  ) async {
    await openApp(tester);

    // The seeded in-progress game was saved as quick-final-score-basic.
    await tester.tap(find.text('Resume Cascadia'));
    await tester.pumpAndSettle();

    expect(find.text('Enter Scores'), findsOneWidget);
    expect(find.text('Avery'), findsOneWidget);
    expect(find.text('52'), findsOneWidget);
  });
}
