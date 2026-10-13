import 'package:scoard_game/application/models/scoring/score_row_label.dart';

class QuickScoreParticipantValues {
  const QuickScoreParticipantValues({
    required this.playerId,
    required this.displayName,
    required this.enteredValues,
    this.entryLabels = const {},
  });

  final String playerId;
  final String displayName;
  final Map<String, int> enteredValues;

  /// Labels shown instead of an entered value, keyed by field id, such as
  /// "Bust" from a value picker. Only kept while a game is in progress.
  final Map<String, ScoreRowLabel> entryLabels;

  QuickScoreParticipantValues withCurrentPlayerName(
    Map<String, String> playerNames,
  ) {
    return QuickScoreParticipantValues(
      playerId: playerId,
      displayName: playerNames[playerId] ?? displayName,
      enteredValues: enteredValues,
      entryLabels: entryLabels,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'playerId': playerId,
      'displayName': displayName,
      'enteredValues': enteredValues,
      if (entryLabels.isNotEmpty)
        'entryLabels': {
          for (final entry in entryLabels.entries) entry.key: entry.value.toJson(),
        },
    };
  }

  factory QuickScoreParticipantValues.fromJson(Map<String, Object?> json) {
    final rawValues = json['enteredValues']! as Map<String, Object?>;
    final rawLabels =
        (json['entryLabels'] as Map<String, Object?>?) ?? const {};

    return QuickScoreParticipantValues(
      playerId: json['playerId']! as String,
      displayName: json['displayName']! as String,
      enteredValues: rawValues.map((key, value) => MapEntry(key, value! as int)),
      entryLabels: rawLabels.map(
        (key, value) => MapEntry(
          key,
          ScoreRowLabel.fromJson(value! as Map<String, Object?>),
        ),
      ),
    );
  }
}
