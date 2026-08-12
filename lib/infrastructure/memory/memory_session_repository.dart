import 'package:scoard_game/application/models/app_summaries.dart';
import 'package:scoard_game/application/models/results/quick_score_result.dart';
import 'package:scoard_game/application/models/results/round_score_result.dart';
import 'package:scoard_game/application/models/sessions/quick_score_participant_values.dart';
import 'package:scoard_game/application/models/sessions/round_score_round_values.dart';
import 'package:scoard_game/application/repositories/session_repository.dart';

class MemorySessionRepository implements SessionRepository {
  MemorySessionRepository._(this._sessions, this._activeSessions);

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
    ], [
      const ActiveSessionSummary(
        id: 'active-cascadia-01',
        gameName: 'Cascadia',
        participantLabel: 'Avery, Mina, Owen',
        progressLabel: 'Round 4 of 6',
      ),
    ]);
  }

  final List<SessionSummary> _sessions;
  final List<ActiveSessionSummary> _activeSessions;

  @override
  Future<int> countCompletedSessions() async => _sessions.length;

  @override
  Future<List<ActiveSessionSummary>> loadActiveSessions({int limit = 3}) async {
    return _activeSessions.take(limit).toList(growable: false);
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
  }

  @override
  Future<void> saveRoundScoreResult({
    required RoundScoreResult result,
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
  }
}