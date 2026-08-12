import 'package:scoard_game/application/models/app_summaries.dart';
import 'package:scoard_game/infrastructure/persistence/db/app_database.dart';

Future<List<SessionSummary>> loadRoundScoreSessionSummaries(
  AppDatabase appDatabase, {
  int limit = 20,
}) async {
  final sessions = await appDatabase.loadRoundScoreSessions(limit: limit);
  final summaries = <SessionSummary>[];

  for (final session in sessions) {
    final playerResults = await appDatabase.loadRoundScorePlayerResults(
      sessionId: session.id,
    );
    final participantLabel = playerResults
        .map((playerResult) => playerResult.displayName)
        .join(', ');
    final winners = playerResults
        .where((playerResult) => playerResult.placement == 1)
        .toList(growable: false);
    final outcomeSummary = winners.length > 1
        ? '${winners.map((winner) => winner.displayName).join(', ')} tied at ${winners.first.cumulativeScore}.'
        : '${winners.first.displayName} won with ${winners.first.cumulativeScore}.';

    summaries.add(
      SessionSummary(
        id: session.id,
        gameName: session.templateDisplayName,
        participantLabel: participantLabel,
        completedAt: session.completedAt,
        outcomeSummary: outcomeSummary,
      ),
    );
  }

  return summaries;
}