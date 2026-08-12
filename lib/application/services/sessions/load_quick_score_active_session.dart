import 'package:scoard_game/application/models/sessions/quick_score_active_session.dart';
import 'package:scoard_game/application/repositories/session_repository.dart';

class LoadQuickScoreActiveSession {
  const LoadQuickScoreActiveSession({required this.sessionRepository});

  final SessionRepository sessionRepository;

  Future<QuickScoreActiveSession?> call({required String sessionId}) {
    return sessionRepository.loadQuickScoreActiveSession(sessionId: sessionId);
  }
}