import 'package:scoard_game/application/models/scoring/preset_prompt_answer.dart';
import 'package:scoard_game/application/models/sessions/player_sort_mode.dart';
import 'package:scoard_game/application/models/sessions/quick_score_participant_values.dart';

class QuickScoreActiveSession {
  const QuickScoreActiveSession({
    required this.sessionId,
    required this.presetId,
    required this.templateDisplayName,
    required this.promptAnswers,
    required this.participantValues,
    required this.updatedAt,
    this.sortMode = PlayerSortMode.playOrder,
  });

  final String sessionId;
  final String presetId;
  final String templateDisplayName;
  final List<PresetPromptAnswer> promptAnswers;
  final List<QuickScoreParticipantValues> participantValues;
  final DateTime updatedAt;
  final PlayerSortMode sortMode;

  String get participantLabel =>
      participantValues.map((participant) => participant.displayName).join(', ');

  String get progressLabel => '${participantValues.length} players ready';

  QuickScoreActiveSession withCurrentPlayerNames(
    Map<String, String> playerNames, {
    DateTime? updatedAt,
  }) {
    return QuickScoreActiveSession(
      sessionId: sessionId,
      presetId: presetId,
      templateDisplayName: templateDisplayName,
      promptAnswers: promptAnswers,
      participantValues: participantValues
          .map((participant) => participant.withCurrentPlayerName(playerNames))
          .toList(growable: false),
      updatedAt: updatedAt ?? this.updatedAt,
      sortMode: sortMode,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'sessionId': sessionId,
      'presetId': presetId,
      'templateDisplayName': templateDisplayName,
      'sortMode': sortMode.name,
        'promptAnswers': promptAnswers
          .map((promptAnswer) => promptAnswer.toJson())
          .toList(growable: false),
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
    final rawPromptAnswers =
        (json['promptAnswers'] as List<Object?>?) ?? const <Object?>[];

    return QuickScoreActiveSession(
      sessionId: json['sessionId']! as String,
      presetId: json['presetId']! as String,
      templateDisplayName: json['templateDisplayName']! as String,
      promptAnswers: rawPromptAnswers
          .map(
            (rawPromptAnswer) => PresetPromptAnswer.fromJson(
              rawPromptAnswer! as Map<String, Object?>,
            ),
          )
          .toList(growable: false),
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
      sortMode: PlayerSortMode.fromStorage(json['sortMode']),
    );
  }
}