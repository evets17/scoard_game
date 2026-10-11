import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/application/models/results/round_score_player_result.dart';
import 'package:scoard_game/application/models/scoring/winner_rule.dart';
import 'package:scoard_game/application/models/sessions/quick_score_active_session.dart';
import 'package:scoard_game/application/models/sessions/quick_score_available_player.dart';
import 'package:scoard_game/application/models/sessions/quick_score_participant_values.dart';
import 'package:scoard_game/application/models/sessions/round_score_active_session.dart';
import 'package:scoard_game/application/models/sessions/round_score_round_values.dart';
import 'package:scoard_game/infrastructure/persistence/db/app_database.dart';
import 'package:scoard_game/infrastructure/persistence/repositories/persistent_player_repository.dart';
import 'package:scoard_game/infrastructure/persistence/repositories/persistent_session_repository.dart';

void main() {
  test('renamed players show their current name in active quick score sessions', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final playerRepository = PersistentPlayerRepository(database);
    final sessionRepository = PersistentSessionRepository(database);

    final player = await playerRepository.createPlayer(displayName: 'Jlues');

    await sessionRepository.saveQuickScoreActiveSession(
      session: QuickScoreActiveSession(
        sessionId: 'quick-draft-1',
        presetId: 'quick-final-score-basic',
        templateDisplayName: 'Quick Score',
        promptAnswers: const [],
        participantValues: [
          QuickScoreParticipantValues(
            playerId: player.id,
            displayName: 'Jlues',
            enteredValues: const {'final-score': 12},
          ),
          const QuickScoreParticipantValues(
            playerId: 'player-missing',
            displayName: 'Guest',
            enteredValues: {'final-score': 3},
          ),
        ],
        updatedAt: DateTime(2026, 10, 11, 9, 0),
      ),
    );

    await playerRepository.renamePlayer(
      playerId: player.id,
      displayName: 'Jules',
    );

    final summaries = await sessionRepository.loadActiveSessions(limit: 10);
    final activeSession = await sessionRepository.loadQuickScoreActiveSession(
      sessionId: 'quick-draft-1',
    );

    expect(summaries.single.participantLabel, 'Jules, Guest');
    expect(
      activeSession?.participantValues.map((participant) => participant.displayName),
      ['Jules', 'Guest'],
    );

    await database.close();
  });

  test('renamed players show their current name in active round score sessions', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final playerRepository = PersistentPlayerRepository(database);
    final sessionRepository = PersistentSessionRepository(database);

    final player = await playerRepository.createPlayer(displayName: 'Jlues');
    QuickScoreParticipantValues values(int score) => QuickScoreParticipantValues(
          playerId: player.id,
          displayName: 'Jlues',
          enteredValues: {'round-score': score},
        );

    await sessionRepository.saveRoundScoreActiveSession(
      session: RoundScoreActiveSession(
        sessionId: 'round-draft-1',
        presetId: 'round-score-basic',
        templateDisplayName: 'Round Score',
        promptAnswers: const [],
        selectedPlayers: [
          QuickScoreAvailablePlayer(id: player.id, displayName: 'Jlues'),
        ],
        savedRounds: [
          RoundScoreRoundValues(roundNumber: 1, participantValues: [values(4)]),
        ],
        currentRoundParticipantValues: [values(0)],
        currentRoundNumber: 2,
        updatedAt: DateTime(2026, 10, 11, 9, 30),
      ),
    );

    await playerRepository.renamePlayer(
      playerId: player.id,
      displayName: 'Jules',
    );

    final summaries = await sessionRepository.loadActiveSessions(limit: 10);
    final activeSession = await sessionRepository.loadRoundScoreActiveSession(
      sessionId: 'round-draft-1',
    );

    expect(summaries.single.participantLabel, 'Jules');
    expect(activeSession?.selectedPlayers.single.displayName, 'Jules');
    expect(
      activeSession?.savedRounds.single.participantValues.single.displayName,
      'Jules',
    );
    expect(
      activeSession?.currentRoundParticipantValues.single.displayName,
      'Jules',
    );
    expect(activeSession?.updatedAt, DateTime(2026, 10, 11, 9, 30));

    await database.close();
  });

  test('renamed players show their current name in completed session history', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final playerRepository = PersistentPlayerRepository(database);
    final sessionRepository = PersistentSessionRepository(database);

    final player = await playerRepository.createPlayer(displayName: 'Jlues');

    await database.saveRoundScoreResult(
      sessionId: 'round-score-test',
      templateId: 'round-score-basic',
      templateDisplayName: 'Round Score',
      winnerRule: WinnerRule.highestScoreWins.name,
      optionsJson: '[]',
      roundCount: 1,
      completedAt: DateTime(2026, 10, 10),
      rounds: [
        RoundScoreRoundValues(
          roundNumber: 1,
          participantValues: [
            QuickScoreParticipantValues(
              playerId: player.id,
              displayName: 'Jlues',
              enteredValues: const {'round-score': 15},
            ),
          ],
        ),
      ],
      playerResults: [
        RoundScorePlayerResult(
          playerId: player.id,
          displayName: 'Jlues',
          cumulativeScore: 15,
          placement: 1,
          isTied: false,
        ),
      ],
    );

    await playerRepository.renamePlayer(
      playerId: player.id,
      displayName: 'Jules',
    );

    final recentSessions = await sessionRepository.loadRecentSessions();

    expect(recentSessions.single.participantLabel, 'Jules');
    expect(recentSessions.single.outcomeSummary, 'Jules won with 15.');

    await database.close();
  });
}
