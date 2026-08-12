import 'package:scoard_game/application/models/sessions/round_score_active_session.dart';
import 'package:scoard_game/application/repositories/session_repository.dart';

class SaveRoundScoreActiveSession {
  const SaveRoundScoreActiveSession({required this.sessionRepository});

  final SessionRepository sessionRepository;

  Future<void> call({required RoundScoreActiveSession session}) {
    return sessionRepository.saveRoundScoreActiveSession(session: session);
  }
}