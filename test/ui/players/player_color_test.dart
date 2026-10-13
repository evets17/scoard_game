import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/application/models/sessions/player_color.dart';
import 'package:scoard_game/application/models/sessions/quick_score_active_session.dart';
import 'package:scoard_game/application/models/sessions/round_score_active_session.dart';
import 'package:scoard_game/bootstrap/app_bootstrap.dart';
import 'package:scoard_game/ui/players/player_color_halo.dart';
import 'package:scoard_game/ui/round_score/round_score_flow_screen.dart';

import '../../support/test_templates.dart';

void main() {
  Future<void> startGame(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

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

    for (final name in ['Avery', 'Jules']) {
      await tester.tap(find.text(name).first);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  }

  PlayerColor? haloFor(WidgetTester tester, String name) {
    return tester
        .widget<PlayerHaloCard>(
          find
              .ancestor(
                of: find.text(name),
                matching: find.byType(PlayerHaloCard),
              )
              .first,
        )
        .color;
  }

  Future<void> pickColor(WidgetTester tester, String name, String color) async {
    await tester.tap(find.text(name).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(color));
    await tester.pumpAndSettle();
  }

  testWidgets('a colour picked for a player shows as a halo on their row', (
    tester,
  ) async {
    await startGame(tester);
    expect(haloFor(tester, 'Avery'), isNull);

    await pickColor(tester, 'Avery', 'Blue');

    // Picking closes the sheet and applies straight away.
    expect(find.text('Switch player'), findsNothing);
    expect(haloFor(tester, 'Avery'), PlayerColor.blue);
    expect(haloFor(tester, 'Jules'), isNull);

    // Other players see who already has the colour, but can still take it.
    await tester.tap(find.text('Jules').first);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Blue, used by Avery'), findsOneWidget);
    await tester.tap(find.byTooltip('Blue'));
    await tester.pumpAndSettle();
    expect(haloFor(tester, 'Jules'), PlayerColor.blue);

    // "No color" takes it away again.
    await pickColor(tester, 'Avery', 'No color');
    expect(haloFor(tester, 'Avery'), isNull);
  });

  test('player colours are saved with a game in progress', () {
    final now = DateTime(2026, 10, 13);
    final round = RoundScoreActiveSession.fromJson(
      RoundScoreActiveSession(
        sessionId: 's1',
        presetId: 'skyjo',
        templateDisplayName: 'Skyjo',
        promptAnswers: const [],
        selectedPlayers: const [],
        savedRounds: const [],
        currentRoundParticipantValues: const [],
        currentRoundNumber: 1,
        updatedAt: now,
        playerColors: const {'p1': PlayerColor.red, 'p2': PlayerColor.white},
      ).toJson(),
    );
    expect(round.playerColors, {'p1': PlayerColor.red, 'p2': PlayerColor.white});

    final quick = QuickScoreActiveSession.fromJson(
      QuickScoreActiveSession(
        sessionId: 's2',
        presetId: 'quick-final-score-basic',
        templateDisplayName: 'Quick',
        promptAnswers: const [],
        participantValues: const [],
        updatedAt: now,
        playerColors: const {'p1': PlayerColor.green},
      ).toJson(),
    );
    expect(quick.playerColors, {'p1': PlayerColor.green});

    // Games saved before colours existed, or with a colour this version
    // does not know, still load.
    expect(PlayerColor.mapFromJson(null), isEmpty);
    expect(PlayerColor.mapFromJson({'p1': 'teal'}), isEmpty);
  });
}
