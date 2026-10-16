/// What a database holds, shown side by side for a backup and this phone
/// before a restore.
class BackupSummary {
  const BackupSummary({
    required this.players,
    required this.finishedGames,
    required this.gamesInProgress,
    this.latestGameAt,
  });

  static const empty =
      BackupSummary(players: 0, finishedGames: 0, gamesInProgress: 0);

  final int players;
  final int finishedGames;
  final int gamesInProgress;

  /// When the most recent game in it was finished or last saved, or null if
  /// it has no games.
  final DateTime? latestGameAt;
}
