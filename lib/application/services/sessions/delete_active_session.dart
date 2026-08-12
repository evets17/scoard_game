import 'package:scoard_game/application/repositories/session_repository.dart';

class DeleteActiveSession {
  const DeleteActiveSession({required this.sessionRepository});

  final SessionRepository sessionRepository;

  Future<void> call({required String sessionId}) {
    return sessionRepository.deleteActiveSession(sessionId: sessionId);
  }
}