import 'package:scoard_game/application/models/app_summaries.dart';
import 'package:scoard_game/infrastructure/persistence/db/app_database.dart';

Future<List<SessionSummary>> loadRoundScoreSessionSummaries(
  AppDatabase appDatabase, {
  Map<String, String> playerNames = const {},
  int limit = 20,
}) async {
  final sessions = await appDatabase.loadRoundScoreSessions(limit: limit);
  final summaries = <SessionSummary>[];

  String nameOf(RoundScorePlayerResultsTableData playerResult) =>
      playerNames[playerResult.playerId] ?? playerResult.displayName;

  for (final session in sessions) {
    final playerResults = await appDatabase.loadRoundScorePlayerResults(
      sessionId: session.id,
    );
    final participantLabel = playerResults.map(nameOf).join(', ');
    final winners = playerResults
        .where((playerResult) => playerResult.placement == 1)
        .toList(growable: false);
    final outcomeSummary = winners.length > 1
        ? '${winners.map(nameOf).join(', ')} tied at ${winners.first.cumulativeScore}.'
        : '${nameOf(winners.first)} won with ${winners.first.cumulativeScore}.';

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