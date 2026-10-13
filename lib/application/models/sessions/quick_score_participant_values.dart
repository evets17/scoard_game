import 'package:scoard_game/application/models/scoring/value_picker_pick.dart';

class QuickScoreParticipantValues {
  const QuickScoreParticipantValues({
    required this.playerId,
    required this.displayName,
    required this.enteredValues,
    this.entryPicks = const {},
  });

  final String playerId;
  final String displayName;
  final Map<String, int> enteredValues;

  /// The value picker tiles an entered value came from, keyed by field id,
  /// so the picker can reopen with them. Only kept while a game is in
  /// progress, and dropped when the value is changed another way.
  final Map<String, ValuePickerPick> entryPicks;

  QuickScoreParticipantValues withCurrentPlayerName(
    Map<String, String> playerNames,
  ) {
    return QuickScoreParticipantValues(
      playerId: playerId,
      displayName: playerNames[playerId] ?? displayName,
      enteredValues: enteredValues,
      entryPicks: entryPicks,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'playerId': playerId,
      'displayName': displayName,
      'enteredValues': enteredValues,
      if (entryPicks.isNotEmpty)
        'entryPicks': {
          for (final entry in entryPicks.entries) entry.key: entry.value.toJson(),
        },
    };
  }

  factory QuickScoreParticipantValues.fromJson(Map<String, Object?> json) {
    final rawValues = json['enteredValues']! as Map<String, Object?>;
    final rawPicks =
        (json['entryPicks'] as Map<String, Object?>?) ?? const {};

    return QuickScoreParticipantValues(
      playerId: json['playerId']! as String,
      displayName: json['displayName']! as String,
      enteredValues: rawValues.map((key, value) => MapEntry(key, value! as int)),
      entryPicks: rawPicks.map(
        (key, value) => MapEntry(
          key,
          ValuePickerPick.fromJson(value! as Map<String, Object?>),
        ),
      ),
    );
  }
}
