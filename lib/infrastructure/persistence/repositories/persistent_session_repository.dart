import 'dart:convert';

import 'package:scoard_game/application/models/app_summaries.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_answer.dart';
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
    final playerNames = await _loadPlayerNames();

    return sessions
        .map(
          (session) => ActiveSessionSummary(
            id: session.id,
            kind: _kindFromStorage(session.sessionKind),
            gameName: session.templateDisplayName,
            participantLabel: _activeParticipantLabel(session, playerNames),
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
    return QuickScoreActiveSession.fromJson(payload).withCurrentPlayerNames(
      await _loadPlayerNames(),
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
    return RoundScoreActiveSession.fromJson(payload).withCurrentPlayerNames(
      await _loadPlayerNames(),
      updatedAt: session.updatedAt,
    );
  }

  @override
  Future<List<SessionSummary>> loadRecentSessions({int limit = 3}) async {
    final quickSessions = await _appDatabase.loadQuickScoreSessions(limit: limit);
    final playerNames = await _loadPlayerNames();
    final quickSummaries = <SessionSummary>[];

    String nameOf(QuickScorePlayerResultsTableData playerResult) =>
        playerNames[playerResult.playerId] ?? playerResult.displayName;

    for (final session in quickSessions) {
      final playerResults = await _appDatabase.loadQuickScorePlayerResults(
        sessionId: session.id,
      );
      final participantLabel = playerResults.map(nameOf).join(', ');
      final winners = playerResults.where((playerResult) => playerResult.placement == 1).toList(growable: false);
      final outcomeSummary = winners.length > 1
          ? '${winners.map(nameOf).join(', ')} tied at ${winners.first.finalScore}.'
          : '${nameOf(winners.first)} won with ${winners.first.finalScore}.';

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
      playerNames: playerNames,
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
    required List<PresetPromptAnswer> promptAnswers,
    required List<QuickScoreParticipantValues> participantValues,
  }) {
    return _appDatabase.saveQuickScoreResult(
      sessionId: result.sessionId,
      templateId: result.templateId,
      templateDisplayName: result.templateDisplayName,
      winnerRule: result.winnerRule.name,
      optionsJson: jsonEncode(
        promptAnswers.map((promptAnswer) => promptAnswer.toJson()).toList(),
      ),
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
    required List<PresetPromptAnswer> promptAnswers,
    required List<RoundScoreRoundValues> rounds,
  }) {
    return _appDatabase.saveRoundScoreResult(
      sessionId: result.sessionId,
      templateId: result.templateId,
      templateDisplayName: result.templateDisplayName,
      winnerRule: result.winnerRule.name,
      optionsJson: jsonEncode(
        promptAnswers.map((promptAnswer) => promptAnswer.toJson()).toList(),
      ),
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

  @override
  Future<Map<String, DateTime>> loadLastPlayedAtByTemplateId() async {
    final lastPlayedAt = await _appDatabase.loadLastCompletedAtByTemplateId();

    // Games in progress count too, as of their last save.
    final activeSessions = await _appDatabase.loadActiveSessions(limit: 1000);
    for (final session in activeSessions) {
      final existing = lastPlayedAt[session.templateId];
      if (existing == null || session.updatedAt.isAfter(existing)) {
        lastPlayedAt[session.templateId] = session.updatedAt;
      }
    }

    return lastPlayedAt;
  }

  @override
  Future<Map<String, DateTime>> loadLastPlayedAtByPlayerId() async {
    final lastPlayedAt = await _appDatabase.loadLastCompletedAtByPlayerId();

    // Games in progress count too, as of their last save.
    final activeSessions = await _appDatabase.loadActiveSessions(limit: 1000);
    for (final session in activeSessions) {
      final payload = jsonDecode(session.payloadJson) as Map<String, Object?>;
      final playerIds = switch (_kindFromStorage(session.sessionKind)) {
        ActiveSessionKind.quickScore => QuickScoreActiveSession.fromJson(payload)
            .participantValues
            .map((participant) => participant.playerId),
        ActiveSessionKind.roundScore => RoundScoreActiveSession.fromJson(payload)
            .selectedPlayers
            .map((player) => player.id),
      };

      for (final playerId in playerIds) {
        final existing = lastPlayedAt[playerId];
        if (existing == null || session.updatedAt.isAfter(existing)) {
          lastPlayedAt[playerId] = session.updatedAt;
        }
      }
    }

    return lastPlayedAt;
  }

  Future<Map<String, String>> _loadPlayerNames() async {
    final players = await _appDatabase.loadPlayers();
    return {
      for (final player in players) player.id: player.displayName,
    };
  }

  String _activeParticipantLabel(
    ActiveSessionsTableData session,
    Map<String, String> playerNames,
  ) {
    final payload = jsonDecode(session.payloadJson) as Map<String, Object?>;

    switch (_kindFromStorage(session.sessionKind)) {
      case ActiveSessionKind.quickScore:
        return QuickScoreActiveSession.fromJson(payload)
            .withCurrentPlayerNames(playerNames)
            .participantLabel;
      case ActiveSessionKind.roundScore:
        return RoundScoreActiveSession.fromJson(payload)
            .withCurrentPlayerNames(playerNames)
            .participantLabel;
    }
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