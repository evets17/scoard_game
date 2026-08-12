import 'package:scoard_game/application/models/sessions/quick_score_participant_values.dart';

class QuickScoreActiveSession {
  const QuickScoreActiveSession({
    required this.sessionId,
    required this.presetId,
    required this.templateDisplayName,
    required this.participantValues,
    required this.updatedAt,
  });

  final String sessionId;
  final String presetId;
  final String templateDisplayName;
  final List<QuickScoreParticipantValues> participantValues;
  final DateTime updatedAt;

  String get participantLabel =>
      participantValues.map((participant) => participant.displayName).join(', ');

  String get progressLabel => '${participantValues.length} players ready';

  Map<String, Object?> toJson() {
    return {
      'sessionId': sessionId,
      'presetId': presetId,
      'templateDisplayName': templateDisplayName,
      'participantValues': participantValues
          .map(
            (participant) => {
              'playerId': participant.playerId,
              'displayName': participant.displayName,
              'enteredValues': participant.enteredValues,
            },
          )
          .toList(growable: false),
    };
  }

  factory QuickScoreActiveSession.fromJson(Map<String, Object?> json) {
    final rawParticipants =
        (json['participantValues'] as List<Object?>?) ?? const <Object?>[];

    return QuickScoreActiveSession(
      sessionId: json['sessionId']! as String,
      presetId: json['presetId']! as String,
      templateDisplayName: json['templateDisplayName']! as String,
      participantValues: rawParticipants
          .map((rawParticipant) {
            final participant = rawParticipant! as Map<String, Object?>;
            final rawValues =
                participant['enteredValues']! as Map<String, Object?>;

            return QuickScoreParticipantValues(
              playerId: participant['playerId']! as String,
              displayName: participant['displayName']! as String,
              enteredValues: rawValues.map(
                (key, value) => MapEntry(key, value! as int),
              ),
            );
          })
          .toList(growable: false),
      updatedAt: DateTime.now(),
    );
  }
}