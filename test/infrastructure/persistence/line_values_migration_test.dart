import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/application/models/sessions/quick_score_participant_values.dart';
import 'package:scoard_game/infrastructure/persistence/db/app_database.dart';

void main() {
  late Directory folder;
  late File file;

  setUp(() {
    folder = Directory.systemTemp.createTempSync('line_values_migration');
    file = File('${folder.path}/app.db');
  });

  tearDown(() => folder.deleteSync(recursive: true));

  test('saved values move from field tables to line tables', () async {
    // Save a game, then put the database back the way version 7 had it.
    final current = AppDatabase.forTesting(NativeDatabase(file));
    await current.saveQuickScoreResult(
      sessionId: 'quick',
      templateId: 'quick-final-score-basic',
      templateDisplayName: 'Quick Score',
      winnerRule: 'highestScoreWins',
      optionsJson: '[]',
      completedAt: DateTime(2026, 10, 1),
      participantValues: const [
        QuickScoreParticipantValues(
          playerId: 'avery',
          displayName: 'Avery',
          enteredValues: {'final-score': 18},
        ),
      ],
      playerResults: const [],
    );
    for (final table in ['quick_score', 'round_score']) {
      await current.customStatement(
        'ALTER TABLE ${table}_line_values_table '
        'RENAME COLUMN line_id TO field_id',
      );
      await current.customStatement(
        'ALTER TABLE ${table}_line_values_table '
        'RENAME TO ${table}_field_values_table',
      );
    }
    await current.customStatement('PRAGMA user_version = 7');
    await current.close();

    final upgraded = AppDatabase.forTesting(NativeDatabase(file));
    final values = await upgraded.loadQuickScoreLineValues(sessionId: 'quick');
    expect(values.single.lineId, 'final-score');
    expect(values.single.integerValue, 18);
    expect(await upgraded.loadRoundScoreLineValues(sessionId: 'none'), isEmpty);
    await upgraded.close();
  });
}
