import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/bootstrap/app_bootstrap.dart';
import 'package:scoard_game/ui/round_score/round_score_flow_screen.dart';
import 'package:scoard_game/ui/settings/settings_screen.dart';
import 'package:scoard_game/ui/settings/stay_awake_controller.dart';
import 'package:scoard_game/ui/theme/app_theme_controller.dart';

import '../../support/test_templates.dart';

void main() {
  late List<bool> wakeLockCalls;
  late List<bool> savedSettings;

  StayAwakeController createController({bool enabled = false}) {
    final calls = wakeLockCalls;
    final saved = savedSettings;
    return StayAwakeController(
      initialEnabled: enabled,
      setWakeLock: (keepAwake) async => calls.add(keepAwake),
      onEnabledChanged: (value) async => saved.add(value),
    );
  }

  setUp(() {
    wakeLockCalls = [];
    savedSettings = [];
  });

  test('keeps the screen on only when enabled and scoring', () {
    final controller = createController();

    controller.beginScoring();
    expect(wakeLockCalls, isEmpty);

    controller.setEnabled(true);
    expect(wakeLockCalls, [true]);
    expect(savedSettings, [true]);

    controller.endScoring();
    expect(wakeLockCalls, [true, false]);

    controller.beginScoring();
    controller.setEnabled(false);
    expect(wakeLockCalls, [true, false, true, false]);
  });

  test('stays on until every scoring screen has ended', () {
    final controller = createController(enabled: true);

    controller.beginScoring();
    controller.beginScoring();
    controller.endScoring();
    expect(wakeLockCalls, [true]);

    controller.endScoring();
    expect(wakeLockCalls, [true, false]);
  });

  testWidgets('score entry keeps the screen on until the game is over', (
    tester,
  ) async {
    final environment = await AppBootstrap.initialize(
      templateCatalog: loadTestTemplateCatalog(),
    );
    final controller = createController(enabled: true);

    await tester.pumpWidget(
      MaterialApp(
        home: RoundScoreFlowScreen(
          loadRoundScoreSetupModel: environment.loadRoundScoreSetupModel,
          preset: environment.templateCatalog.byId('round-score-basic'),
          createPlayer: environment.createPlayer,
          renamePlayer: environment.renamePlayer,
          stayAwakeController: controller,
          rememberSetupPlayerGroup: environment.rememberSetupPlayerGroup,
          saveRoundScoreSession: environment.saveRoundScoreSession,
          saveRoundScoreActiveSession: environment.saveRoundScoreActiveSession,
          deleteActiveSession: environment.deleteActiveSession,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Choosing players is not scoring yet.
    expect(wakeLockCalls, isEmpty);

    await tester.tap(find.text('Avery').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jules').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(wakeLockCalls, [true]);

    await tester.tap(find.text('Next Round >>'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Game Over'));
    await tester.pumpAndSettle();

    expect(find.text('Final Result'), findsOneWidget);
    expect(wakeLockCalls, [true, false]);
  });

  testWidgets('settings switch turns the option on and saves it', (
    tester,
  ) async {
    final controller = createController();

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          themeController: AppThemeController(),
          stayAwakeController: controller,
        ),
      ),
    );

    await tester.scrollUntilVisible(find.text('Stay awake when scoring'), 200);
    await tester.tap(find.text('Stay awake when scoring'));
    await tester.pumpAndSettle();

    expect(controller.enabled, isTrue);
    expect(savedSettings, [true]);
    expect(wakeLockCalls, isEmpty);
  });
}
