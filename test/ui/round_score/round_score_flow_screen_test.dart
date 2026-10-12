import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/bootstrap/app_bootstrap.dart';
import 'package:scoard_game/ui/round_score/round_score_flow_screen.dart';

import '../../support/test_templates.dart';

void main() {
  testWidgets('round scoring can advance with zero-value rounds', (
    tester,
  ) async {
    final environment = await AppBootstrap.initialize(
      templateCatalog: loadTestTemplateCatalog(),
    );

    await tester.pumpWidget(
      MaterialApp(
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
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Avery').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jules').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Round 1'), findsOneWidget);

    await tester.tap(find.text('Next Round >>'));
    await tester.pumpAndSettle();

    expect(find.text('Round 2'), findsOneWidget);

    await tester.tap(find.text('Game Over'));
    await tester.pumpAndSettle();

    expect(find.text('Final Result'), findsOneWidget);
    expect(find.text('Rounds played: 1'), findsOneWidget);
  });
}
