class PlayerSummary {
  const PlayerSummary({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}

class GameSummary {
  const GameSummary({
    required this.id,
    required this.name,
    required this.scoringStyle,
  });

  final String id;
  final String name;
  final String scoringStyle;
}

class SessionSummary {
  const SessionSummary({
    required this.id,
    required this.gameName,
    required this.participantLabel,
    required this.completedAt,
    required this.outcomeSummary,
  });

  final String id;
  final String gameName;
  final String participantLabel;
  final DateTime completedAt;
  final String outcomeSummary;
}

class ActiveSessionSummary {
  const ActiveSessionSummary({
    required this.id,
    required this.gameName,
    required this.participantLabel,
    required this.progressLabel,
  });

  final String id;
  final String gameName;
  final String participantLabel;
  final String progressLabel;
}