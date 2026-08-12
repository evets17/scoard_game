import 'package:scoard_game/application/models/sessions/quick_score_available_player.dart';
import 'package:scoard_game/application/models/sessions/quick_score_participant_values.dart';
import 'package:scoard_game/application/models/sessions/round_score_round_values.dart';

class RoundScoreActiveSession {
  const RoundScoreActiveSession({
    required this.sessionId,
    required this.presetId,
    required this.templateDisplayName,
    required this.selectedPlayers,
    required this.savedRounds,
    required this.currentRoundParticipantValues,
    required this.currentRoundNumber,
    required this.updatedAt,
  });

  final String sessionId;
  final String presetId;
  final String templateDisplayName;
  final List<QuickScoreAvailablePlayer> selectedPlayers;
  final List<RoundScoreRoundValues> savedRounds;
  final List<QuickScoreParticipantValues> currentRoundParticipantValues;
  final int currentRoundNumber;
  final DateTime updatedAt;

  String get participantLabel =>
      selectedPlayers.map((player) => player.displayName).join(', ');

  String get progressLabel => 'Round $currentRoundNumber';

  Map<String, Object?> toJson() {
    return {
      'sessionId': sessionId,
      'presetId': presetId,
      'templateDisplayName': templateDisplayName,
      'selectedPlayers': selectedPlayers
          .map(
            (player) => {
              'id': player.id,
              'displayName': player.displayName,
            },
          )
          .toList(growable: false),
      'savedRounds': savedRounds
          .map(
            (round) => {
              'roundNumber': round.roundNumber,
              'participantValues': round.participantValues
                  .map(
                    (participant) => {
                      'playerId': participant.playerId,
                      'displayName': participant.displayName,
                      'enteredValues': participant.enteredValues,
                    },
                  )
                  .toList(growable: false),
            },
          )
          .toList(growable: false),
      'currentRoundParticipantValues': currentRoundParticipantValues
          .map(
            (participant) => {
              'playerId': participant.playerId,
              'displayName': participant.displayName,
              'enteredValues': participant.enteredValues,
            },
          )
          .toList(growable: false),
      'currentRoundNumber': currentRoundNumber,
    };
  }

  factory RoundScoreActiveSession.fromJson(Map<String, Object?> json) {
    final rawSelectedPlayers =
        (json['selectedPlayers'] as List<Object?>?) ?? const <Object?>[];
    final rawSavedRounds =
        (json['savedRounds'] as List<Object?>?) ?? const <Object?>[];
    final rawCurrentRoundParticipantValues =
        (json['currentRoundParticipantValues'] as List<Object?>?) ??
            const <Object?>[];

    QuickScoreParticipantValues parseParticipant(Object? rawParticipant) {
      final participant = rawParticipant! as Map<String, Object?>;
      final rawValues = participant['enteredValues']! as Map<String, Object?>;

      return QuickScoreParticipantValues(
        playerId: participant['playerId']! as String,
        displayName: participant['displayName']! as String,
        enteredValues: rawValues.map(
          (key, value) => MapEntry(key, value! as int),
        ),
      );
    }

    return RoundScoreActiveSession(
      sessionId: json['sessionId']! as String,
      presetId: json['presetId']! as String,
      templateDisplayName: json['templateDisplayName']! as String,
      selectedPlayers: rawSelectedPlayers
          .map((rawPlayer) {
            final player = rawPlayer! as Map<String, Object?>;
            return QuickScoreAvailablePlayer(
              id: player['id']! as String,
              displayName: player['displayName']! as String,
            );
          })
          .toList(growable: false),
      savedRounds: rawSavedRounds
          .map((rawRound) {
            final round = rawRound! as Map<String, Object?>;
            final participantValues =
                (round['participantValues'] as List<Object?>?) ??
                    const <Object?>[];

            return RoundScoreRoundValues(
              roundNumber: round['roundNumber']! as int,
              participantValues: participantValues
                  .map(parseParticipant)
                  .toList(growable: false),
            );
          })
          .toList(growable: false),
      currentRoundParticipantValues: rawCurrentRoundParticipantValues
          .map(parseParticipant)
          .toList(growable: false),
      currentRoundNumber: json['currentRoundNumber']! as int,
      updatedAt: DateTime.now(),
    );
  }
}