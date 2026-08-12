import 'package:scoard_game/application/models/app_summaries.dart';
import 'package:scoard_game/application/models/results/quick_score_result.dart';
import 'package:scoard_game/application/models/results/round_score_result.dart';
import 'package:scoard_game/application/models/sessions/quick_score_participant_values.dart';
import 'package:scoard_game/application/models/sessions/round_score_round_values.dart';

abstract class SessionRepository {
  Future<int> countCompletedSessions();

  Future<List<ActiveSessionSummary>> loadActiveSessions({int limit = 3});

  Future<List<SessionSummary>> loadRecentSessions({int limit = 3});

  Future<void> saveQuickScoreResult({
    required QuickScoreResult result,
    required List<QuickScoreParticipantValues> participantValues,
  });

  Future<void> saveRoundScoreResult({
    required RoundScoreResult result,
    required List<RoundScoreRoundValues> rounds,
  });
}