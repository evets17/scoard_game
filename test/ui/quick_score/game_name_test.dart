import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_answer.dart';
import 'package:scoard_game/bootstrap/app_bootstrap.dart';
import 'package:scoard_game/ui/quick_score/quick_score_flow_screen.dart';

import '../../support/test_templates.dart';

void main() {
  testWidgets('a Quick Score game is shown and saved under its game name', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final environment = await AppBootstrap.initialize(
      templateCatalog: loadTestTemplateCatalog(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: QuickScoreFlowScreen(
          loadQuickScoreSetupModel: environment.loadQuickScoreSetupModel,
          preset: environment.templateCatalog.byId('quick-final-score-basic'),
          initialPromptAnswers: const [
            PresetPromptAnswer.text(id: 'game-name', value: 'Catan'),
          ],
          createPlayer: environment.createPlayer,
          renamePlayer: environment.renamePlayer,
          stayAwakeController: environment.stayAwakeController,
          rememberSetupPlayerGroup: environment.rememberSetupPlayerGroup,
          saveQuickScoreSession: environment.saveQuickScoreSession,
          saveQuickScoreActiveSession: environment.saveQuickScoreActiveSession,
          deleteActiveSession: environment.deleteActiveSession,
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final name in ['Avery', 'Jules']) {
      await tester.tap(find.text(name).first);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Under the title while scoring.
    expect(find.text('Enter Scores'), findsOneWidget);
    expect(find.text('Catan'), findsOneWidget);

    for (final button in find.byIcon(Icons.add).evaluate().toList()) {
      await tester.tap(find.byWidget(button.widget));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    // In progress, it is listed under its name.
    final active = await environment.sessionRepository.loadActiveSessions(
      limit: 10,
    );
    expect(active.map((session) => session.gameName), contains('Catan'));

    await tester.tap(find.text('Game Over'));
    await tester.pumpAndSettle();
    final recent = await environment.sessionRepository.loadRecentSessions(
      limit: 1,
    );
    expect(recent.single.gameName, 'Catan');
    expect(
      await environment.sessionRepository.loadRecentGameNames(
        templateId: 'quick-final-score-basic',
      ),
      contains('Catan'),
    );
  });
}
