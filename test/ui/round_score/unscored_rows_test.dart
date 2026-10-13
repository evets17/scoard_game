import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/application/models/sessions/round_score_active_session.dart';
import 'package:scoard_game/bootstrap/app_bootstrap.dart';
import 'package:scoard_game/bootstrap/app_environment.dart';
import 'package:scoard_game/ui/round_score/round_score_flow_screen.dart';

import '../../support/test_templates.dart';

void main() {
  Future<AppEnvironment> environment() => AppBootstrap.initialize(
        templateCatalog: loadTestTemplateCatalog(),
      );

  Future<void> pumpRoundScreen(
    WidgetTester tester,
    AppEnvironment environment, {
    RoundScoreActiveSession? resume,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        home: RoundScoreFlowScreen(
          loadRoundScoreSetupModel: environment.loadRoundScoreSetupModel,
          preset: environment.templateCatalog.byId('round-score-basic'),
          createPlayer: environment.createPlayer,
          renamePlayer: environment.renamePlayer,
          stayAwakeController: environment.stayAwakeController,
          rememberSetupPlayerGroup: environment.rememberSetupPlayerGroup,
          saveRoundScoreSession: environment.saveRoundScoreSession,
          saveRoundScoreActiveSession: environment.saveRoundScoreActiveSession,
          deleteActiveSession: environment.deleteActiveSession,
          initialActiveSession: resume,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder rowFor(String name) =>
      find.ancestor(of: find.text(name), matching: find.byType(Card)).first;

  Finder scoreIn(String name, String text) =>
      find.descendant(of: rowFor(name), matching: find.text(text));

  testWidgets('rows show a dash until a score is entered', (tester) async {
    final env = await environment();
    await pumpRoundScreen(tester, env);
    await tester.tap(find.text('Avery').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jules').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(scoreIn('Avery', '–'), findsOneWidget);
    expect(scoreIn('Jules', '–'), findsOneWidget);

    // +/- starts from 0 and replaces the dash.
    await tester.tap(
      find.descendant(
        of: rowFor('Avery'),
        matching: find.byTooltip('Increase score'),
      ),
    );
    await tester.pump();
    expect(scoreIn('Avery', '1'), findsWidgets);
    expect(scoreIn('Avery', '–'), findsNothing);

    // Entering 0 shows 0, not a dash.
    await tester.tap(scoreIn('Jules', '–'));
    await tester.pumpAndSettle();
    expect(find.text('No score yet'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '0'));
    await tester.pump();
    await tester.tap(find.text('Replace -> 0'));
    await tester.pumpAndSettle();
    expect(scoreIn('Jules', '–'), findsNothing);

    // Moving on is allowed; an untouched row counts as 0 and the next round
    // starts with dashes again.
    await tester.tap(find.text('Next Round >>'));
    await tester.pumpAndSettle();
    expect(find.text('Round 2'), findsOneWidget);
    expect(scoreIn('Avery', '–'), findsOneWidget);
    expect(scoreIn('Jules', '–'), findsOneWidget);
  });

  testWidgets('dashes survive saving and resuming a game', (tester) async {
    // Start a game, score only Avery, then resume from what was saved.
    final env = await environment();
    await pumpRoundScreen(tester, env);
    await tester.tap(find.text('Avery').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jules').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: rowFor('Avery'),
        matching: find.byTooltip('Increase score'),
      ),
    );
    await tester.pumpAndSettle();

    final activeSummaries =
        await env.sessionRepository.loadActiveSessions(limit: 10);
    final saved = await env.loadRoundScoreActiveSession(
      sessionId: activeSummaries
          .firstWhere((summary) => summary.gameName == 'Round Score')
          .id,
    );

    await tester.pumpWidget(const SizedBox());
    await pumpRoundScreen(tester, env, resume: saved);

    expect(scoreIn('Avery', '1'), findsWidgets);
    expect(scoreIn('Jules', '–'), findsOneWidget);
  });
}
