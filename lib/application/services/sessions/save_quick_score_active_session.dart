import 'package:scoard_game/application/models/sessions/quick_score_active_session.dart';
import 'package:scoard_game/application/repositories/session_repository.dart';

class SaveQuickScoreActiveSession {
  const SaveQuickScoreActiveSession({required this.sessionRepository});

  final SessionRepository sessionRepository;

  Future<void> call({required QuickScoreActiveSession session}) {
    return sessionRepository.saveQuickScoreActiveSession(session: session);
  }
}