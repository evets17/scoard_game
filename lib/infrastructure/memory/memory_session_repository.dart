import 'package:scoard_game/application/models/app_summaries.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_answer.dart';
import 'package:scoard_game/application/models/results/quick_score_result.dart';
import 'package:scoard_game/application/models/results/round_score_result.dart';
import 'package:scoard_game/application/models/sessions/quick_score_active_session.dart';
import 'package:scoard_game/application/models/sessions/quick_score_participant_values.dart';
import 'package:scoard_game/application/models/sessions/round_score_active_session.dart';
import 'package:scoard_game/application/models/sessions/round_score_round_values.dart';
import 'package:scoard_game/application/repositories/session_repository.dart';

class MemorySessionRepository implements SessionRepository {
  MemorySessionRepository._(
    this._sessions,
    this._quickActiveSessions,
    this._roundActiveSessions,
  );

  factory MemorySessionRepository.seeded() {
    final now = DateTime.now();

    return MemorySessionRepository._([
      SessionSummary(
        id: 'session-qwinto-01',
        gameName: 'Qwinto',
        participantLabel: 'Avery, Mina, Rio',
        completedAt: now.subtract(const Duration(days: 1)),
        outcomeSummary: 'Mina won with 143 points.',
      ),
      SessionSummary(
        id: 'session-skyjo-01',
        gameName: 'Skyjo',
        participantLabel: 'Jules, Owen, Avery',
        completedAt: now.subtract(const Duration(days: 4)),
        outcomeSummary: 'Owen finished lowest at 52.',
      ),
      SessionSummary(
        id: 'session-azul-01',
        gameName: 'Azul',
        participantLabel: 'Rio, Mina',
        completedAt: now.subtract(const Duration(days: 8)),
        outcomeSummary: 'Rio took the lead after final wall bonuses.',
      ),
    ], {
      'active-cascadia-01': QuickScoreActiveSession(
        sessionId: 'active-cascadia-01',
        presetId: 'quick-final-score-basic',
        templateDisplayName: 'Cascadia',
        promptAnswers: const [],
        participantValues: const [
          QuickScoreParticipantValues(
            playerId: 'player-avery',
            displayName: 'Avery',
            enteredValues: {'final-score': 52},
          ),
          QuickScoreParticipantValues(
            playerId: 'player-mina',
            displayName: 'Mina',
            enteredValues: {'final-score': 47},
          ),
          QuickScoreParticipantValues(
            playerId: 'player-owen',
            displayName: 'Owen',
            enteredValues: {'final-score': 49},
          ),
        ],
        updatedAt: now,
      ),
    }, <String, RoundScoreActiveSession>{});
  }

  final List<SessionSummary> _sessions;
  final Map<String, QuickScoreActiveSession> _quickActiveSessions;
  final Map<String, RoundScoreActiveSession> _roundActiveSessions;
  final Map<String, DateTime> _lastCompletedAtByPlayerId = {};

  @override
  Future<int> countCompletedSessions() async => _sessions.length;

  @override
  Future<List<ActiveSessionSummary>> loadActiveSessions({int limit = 3}) async {
    final summaries = <ActiveSessionSummary>[
      ..._quickActiveSessions.values.map(_activeSummaryForQuick),
      ..._roundActiveSessions.values.map(_activeSummaryForRound),
    ]..sort((left, right) => right.id.compareTo(left.id));

    return summaries.take(limit).toList(growable: false);
  }

  @override
  Future<QuickScoreActiveSession?> loadQuickScoreActiveSession({
    required String sessionId,
  }) async {
    return _quickActiveSessions[sessionId];
  }

  @override
  Future<RoundScoreActiveSession?> loadRoundScoreActiveSession({
    required String sessionId,
  }) async {
    return _roundActiveSessions[sessionId];
  }

  @override
  Future<List<SessionSummary>> loadRecentSessions({int limit = 3}) async {
    final sessions = _sessions.toList(growable: false)
      ..sort((left, right) => right.completedAt.compareTo(left.completedAt));

    return sessions.take(limit).toList(growable: false);
  }

  @override
  Future<void> saveQuickScoreResult({
    required QuickScoreResult result,
    required List<PresetPromptAnswer> promptAnswers,
    required List<QuickScoreParticipantValues> participantValues,
  }) async {
    final winnerLabel = result.winners.map((winner) => winner.displayName).join(', ');
    final outcomeSummary = result.winners.length > 1
        ? '$winnerLabel tied at ${result.winners.first.finalScore}.'
        : '$winnerLabel won with ${result.winners.first.finalScore}.';

    _sessions.removeWhere((session) => session.id == result.sessionId);
    _sessions.add(
      SessionSummary(
        id: result.sessionId,
        gameName: result.templateDisplayName,
        participantLabel: result.playerResults.map((player) => player.displayName).join(', '),
        completedAt: result.completedAt,
        outcomeSummary: outcomeSummary,
      ),
    );
    _quickActiveSessions.remove(result.sessionId);
    _roundActiveSessions.remove(result.sessionId);
    _recordCompleted(
      result.playerResults.map((player) => player.playerId),
      result.completedAt,
    );
  }

  @override
  Future<void> saveQuickScoreActiveSession({
    required QuickScoreActiveSession session,
  }) async {
    _quickActiveSessions[session.sessionId] = session;
    _roundActiveSessions.remove(session.sessionId);
  }

  @override
  Future<void> saveRoundScoreResult({
    required RoundScoreResult result,
    required List<PresetPromptAnswer> promptAnswers,
    required List<RoundScoreRoundValues> rounds,
  }) async {
    final winnerLabel = result.winners.map((winner) => winner.displayName).join(', ');
    final outcomeSummary = result.winners.length > 1
        ? '$winnerLabel tied at ${result.winners.first.cumulativeScore}.'
        : '$winnerLabel won with ${result.winners.first.cumulativeScore}.';

    _sessions.removeWhere((session) => session.id == result.sessionId);
    _sessions.add(
      SessionSummary(
        id: result.sessionId,
        gameName: result.templateDisplayName,
        participantLabel: result.playerResults.map((player) => player.displayName).join(', '),
        completedAt: result.completedAt,
        outcomeSummary: outcomeSummary,
      ),
    );
    _quickActiveSessions.remove(result.sessionId);
    _roundActiveSessions.remove(result.sessionId);
    _recordCompleted(
      result.playerResults.map((player) => player.playerId),
      result.completedAt,
    );
  }

  @override
  Future<void> saveRoundScoreActiveSession({
    required RoundScoreActiveSession session,
  }) async {
    _roundActiveSessions[session.sessionId] = session;
    _quickActiveSessions.remove(session.sessionId);
  }

  @override
  Future<Map<String, DateTime>> loadLastPlayedAtByPlayerId() async {
    final lastPlayedAt = {..._lastCompletedAtByPlayerId};

    void record(String playerId, DateTime playedAt) {
      final existing = lastPlayedAt[playerId];
      if (existing == null || playedAt.isAfter(existing)) {
        lastPlayedAt[playerId] = playedAt;
      }
    }

    for (final session in _quickActiveSessions.values) {
      for (final participant in session.participantValues) {
        record(participant.playerId, session.updatedAt);
      }
    }
    for (final session in _roundActiveSessions.values) {
      for (final player in session.selectedPlayers) {
        record(player.id, session.updatedAt);
      }
    }

    return lastPlayedAt;
  }

  void _recordCompleted(Iterable<String> playerIds, DateTime completedAt) {
    for (final playerId in playerIds) {
      final existing = _lastCompletedAtByPlayerId[playerId];
      if (existing == null || completedAt.isAfter(existing)) {
        _lastCompletedAtByPlayerId[playerId] = completedAt;
      }
    }
  }

  @override
  Future<void> deleteActiveSession({required String sessionId}) async {
    _quickActiveSessions.remove(sessionId);
    _roundActiveSessions.remove(sessionId);
  }

  ActiveSessionSummary _activeSummaryForQuick(QuickScoreActiveSession session) {
    return ActiveSessionSummary(
      id: session.sessionId,
      kind: ActiveSessionKind.quickScore,
      gameName: session.templateDisplayName,
      participantLabel: session.participantLabel,
      progressLabel: session.progressLabel,
    );
  }

  ActiveSessionSummary _activeSummaryForRound(RoundScoreActiveSession session) {
    return ActiveSessionSummary(
      id: session.sessionId,
      kind: ActiveSessionKind.roundScore,
      gameName: session.templateDisplayName,
      participantLabel: session.participantLabel,
      progressLabel: session.progressLabel,
    );
  }
}