import 'package:scoard_game/application/models/sessions/round_score_active_session.dart';
import 'package:scoard_game/application/repositories/session_repository.dart';

class LoadRoundScoreActiveSession {
  const LoadRoundScoreActiveSession({required this.sessionRepository});

  final SessionRepository sessionRepository;

  Future<RoundScoreActiveSession?> call({required String sessionId}) {
    return sessionRepository.loadRoundScoreActiveSession(sessionId: sessionId);
  }
}