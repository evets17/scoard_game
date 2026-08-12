import 'dart:convert';

import 'package:scoard_game/application/models/app_summaries.dart';
import 'package:scoard_game/application/models/results/quick_score_result.dart';
import 'package:scoard_game/application/models/results/round_score_result.dart';
import 'package:scoard_game/application/models/sessions/quick_score_active_session.dart';
import 'package:scoard_game/application/models/sessions/quick_score_participant_values.dart';
import 'package:scoard_game/application/models/sessions/round_score_active_session.dart';
import 'package:scoard_game/application/models/sessions/round_score_round_values.dart';
import 'package:scoard_game/application/repositories/session_repository.dart';
import 'package:scoard_game/infrastructure/persistence/db/app_database.dart';
import 'package:scoard_game/infrastructure/persistence/repositories/persistent_round_score_support.dart';

class PersistentSessionRepository implements SessionRepository {
  PersistentSessionRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  @override
  Future<int> countCompletedSessions() async {
    final quickScoreCount = await _appDatabase.countCompletedQuickScoreSessions();
    final roundScoreCount = await _appDatabase.countCompletedRoundScoreSessions();

    return quickScoreCount + roundScoreCount;
  }

  @override
  Future<List<ActiveSessionSummary>> loadActiveSessions({int limit = 3}) async {
    final sessions = await _appDatabase.loadActiveSessions(limit: limit);

    return sessions
        .map(
          (session) => ActiveSessionSummary(
            id: session.id,
            kind: _kindFromStorage(session.sessionKind),
            gameName: session.templateDisplayName,
            participantLabel: session.participantLabel,
            progressLabel: session.progressLabel,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<QuickScoreActiveSession?> loadQuickScoreActiveSession({
    required String sessionId,
  }) async {
    final session = await _appDatabase.loadActiveSession(sessionId: sessionId);
    if (session == null || session.sessionKind != 'quickScore') {
      return null;
    }

    final payload = jsonDecode(session.payloadJson) as Map<String, Object?>;
    final activeSession = QuickScoreActiveSession.fromJson(payload);
    return QuickScoreActiveSession(
      sessionId: activeSession.sessionId,
      presetId: activeSession.presetId,
      templateDisplayName: activeSession.templateDisplayName,
      participantValues: activeSession.participantValues,
      updatedAt: session.updatedAt,
    );
  }

  @override
  Future<RoundScoreActiveSession?> loadRoundScoreActiveSession({
    required String sessionId,
  }) async {
    final session = await _appDatabase.loadActiveSession(sessionId: sessionId);
    if (session == null || session.sessionKind != 'roundScore') {
      return null;
    }

    final payload = jsonDecode(session.payloadJson) as Map<String, Object?>;
    final activeSession = RoundScoreActiveSession.fromJson(payload);
    return RoundScoreActiveSession(
      sessionId: activeSession.sessionId,
      presetId: activeSession.presetId,
      templateDisplayName: activeSession.templateDisplayName,
      selectedPlayers: activeSession.selectedPlayers,
      savedRounds: activeSession.savedRounds,
      currentRoundParticipantValues: activeSession.currentRoundParticipantValues,
      currentRoundNumber: activeSession.currentRoundNumber,
      updatedAt: session.updatedAt,
    );
  }

  @override
  Future<List<SessionSummary>> loadRecentSessions({int limit = 3}) async {
    final quickSessions = await _appDatabase.loadQuickScoreSessions(limit: limit);
    final quickSummaries = <SessionSummary>[];

    for (final session in quickSessions) {
      final playerResults = await _appDatabase.loadQuickScorePlayerResults(
        sessionId: session.id,
      );
      final participantLabel = playerResults
          .map((playerResult) => playerResult.displayName)
          .join(', ');
      final winners = playerResults.where((playerResult) => playerResult.placement == 1).toList(growable: false);
      final outcomeSummary = winners.length > 1
          ? '${winners.map((winner) => winner.displayName).join(', ')} tied at ${winners.first.finalScore}.'
          : '${winners.first.displayName} won with ${winners.first.finalScore}.';

      quickSummaries.add(
        SessionSummary(
          id: session.id,
          gameName: session.templateDisplayName,
          participantLabel: participantLabel,
          completedAt: session.completedAt,
          outcomeSummary: outcomeSummary,
        ),
      );
    }

    final roundSummaries = await loadRoundScoreSessionSummaries(
      _appDatabase,
      limit: limit,
    );

    final summaries = [
      ...quickSummaries,
      ...roundSummaries,
    ]..sort((left, right) => right.completedAt.compareTo(left.completedAt));

    return summaries.take(limit).toList(growable: false);
  }

  @override
  Future<void> saveQuickScoreResult({
    required QuickScoreResult result,
    required List<QuickScoreParticipantValues> participantValues,
  }) {
    return _appDatabase.saveQuickScoreResult(
      sessionId: result.sessionId,
      templateId: result.templateId,
      templateDisplayName: result.templateDisplayName,
      winnerRule: result.winnerRule.name,
      completedAt: result.completedAt,
      participantValues: participantValues,
      playerResults: result.playerResults,
    );
  }

  @override
  Future<void> saveQuickScoreActiveSession({
    required QuickScoreActiveSession session,
  }) {
    return _appDatabase.saveActiveSession(
      sessionId: session.sessionId,
      sessionKind: 'quickScore',
      templateId: session.presetId,
      templateDisplayName: session.templateDisplayName,
      participantLabel: session.participantLabel,
      progressLabel: session.progressLabel,
      payloadJson: jsonEncode(session.toJson()),
      updatedAt: session.updatedAt,
    );
  }

  @override
  Future<void> saveRoundScoreResult({
    required RoundScoreResult result,
    required List<RoundScoreRoundValues> rounds,
  }) {
    return _appDatabase.saveRoundScoreResult(
      sessionId: result.sessionId,
      templateId: result.templateId,
      templateDisplayName: result.templateDisplayName,
      winnerRule: result.winnerRule.name,
      roundCount: result.roundCount,
      completedAt: result.completedAt,
      rounds: rounds,
      playerResults: result.playerResults,
    );
  }

  @override
  Future<void> saveRoundScoreActiveSession({
    required RoundScoreActiveSession session,
  }) {
    return _appDatabase.saveActiveSession(
      sessionId: session.sessionId,
      sessionKind: 'roundScore',
      templateId: session.presetId,
      templateDisplayName: session.templateDisplayName,
      participantLabel: session.participantLabel,
      progressLabel: session.progressLabel,
      payloadJson: jsonEncode(session.toJson()),
      updatedAt: session.updatedAt,
    );
  }

  @override
  Future<void> deleteActiveSession({required String sessionId}) {
    return _appDatabase.deleteActiveSession(sessionId: sessionId);
  }

  ActiveSessionKind _kindFromStorage(String sessionKind) {
    switch (sessionKind) {
      case 'quickScore':
        return ActiveSessionKind.quickScore;
      case 'roundScore':
        return ActiveSessionKind.roundScore;
      default:
        throw StateError('Unknown active session kind: $sessionKind');
    }
  }
}