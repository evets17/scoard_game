import 'package:scoard_game/application/models/scoring/preset_prompt_answer.dart';
import 'package:scoard_game/application/models/sessions/player_color.dart';
import 'package:scoard_game/application/models/sessions/player_sort_mode.dart';
import 'package:scoard_game/application/models/sessions/quick_score_available_player.dart';
import 'package:scoard_game/application/models/sessions/quick_score_participant_values.dart';
import 'package:scoard_game/application/models/sessions/round_score_round_values.dart';

class RoundScoreActiveSession {
  const RoundScoreActiveSession({
    required this.sessionId,
    required this.presetId,
    required this.templateDisplayName,
    required this.promptAnswers,
    required this.selectedPlayers,
    required this.savedRounds,
    required this.currentRoundParticipantValues,
    required this.currentRoundNumber,
    required this.updatedAt,
    this.sortMode = PlayerSortMode.playOrder,
    this.playerColors = const {},
    this.showSheet = false,
  });

  final String sessionId;
  final String presetId;
  final String templateDisplayName;
  final List<PresetPromptAnswer> promptAnswers;
  final List<QuickScoreAvailablePlayer> selectedPlayers;
  final List<RoundScoreRoundValues> savedRounds;
  final List<QuickScoreParticipantValues> currentRoundParticipantValues;
  final int currentRoundNumber;
  final DateTime updatedAt;
  final PlayerSortMode sortMode;

  /// Colours given to players for this game, by player id.
  final Map<String, PlayerColor> playerColors;

  /// Whether the game shows the sheet view rather than player cards.
  final bool showSheet;

  String get participantLabel =>
      selectedPlayers.map((player) => player.displayName).join(', ');

  String get progressLabel => 'Round $currentRoundNumber';

  RoundScoreActiveSession withCurrentPlayerNames(
    Map<String, String> playerNames, {
    DateTime? updatedAt,
  }) {
    List<QuickScoreParticipantValues> renameParticipants(
      List<QuickScoreParticipantValues> participants,
    ) {
      return participants
          .map((participant) => participant.withCurrentPlayerName(playerNames))
          .toList(growable: false);
    }

    return RoundScoreActiveSession(
      sessionId: sessionId,
      presetId: presetId,
      templateDisplayName: templateDisplayName,
      promptAnswers: promptAnswers,
      selectedPlayers: selectedPlayers
          .map((player) => player.withCurrentPlayerName(playerNames))
          .toList(growable: false),
      savedRounds: savedRounds
          .map(
            (round) => RoundScoreRoundValues(
              roundNumber: round.roundNumber,
              participantValues: renameParticipants(round.participantValues),
            ),
          )
          .toList(growable: false),
      currentRoundParticipantValues:
          renameParticipants(currentRoundParticipantValues),
      currentRoundNumber: currentRoundNumber,
      updatedAt: updatedAt ?? this.updatedAt,
      sortMode: sortMode,
      playerColors: playerColors,
      showSheet: showSheet,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'sessionId': sessionId,
      'presetId': presetId,
      'templateDisplayName': templateDisplayName,
      'sortMode': sortMode.name,
      if (showSheet) 'showSheet': true,
      if (playerColors.isNotEmpty)
        'playerColors': PlayerColor.mapToJson(playerColors),
        'promptAnswers': promptAnswers
          .map((promptAnswer) => promptAnswer.toJson())
          .toList(growable: false),
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
                  .map((participant) => participant.toJson())
                  .toList(growable: false),
            },
          )
          .toList(growable: false),
      'currentRoundParticipantValues': currentRoundParticipantValues
          .map((participant) => participant.toJson())
          .toList(growable: false),
      'currentRoundNumber': currentRoundNumber,
    };
  }

  factory RoundScoreActiveSession.fromJson(Map<String, Object?> json) {
    final rawSelectedPlayers =
        (json['selectedPlayers'] as List<Object?>?) ?? const <Object?>[];
    final rawPromptAnswers =
      (json['promptAnswers'] as List<Object?>?) ?? const <Object?>[];
    final rawSavedRounds =
        (json['savedRounds'] as List<Object?>?) ?? const <Object?>[];
    final rawCurrentRoundParticipantValues =
        (json['currentRoundParticipantValues'] as List<Object?>?) ??
            const <Object?>[];

    QuickScoreParticipantValues parseParticipant(Object? rawParticipant) {
      return QuickScoreParticipantValues.fromJson(
        rawParticipant! as Map<String, Object?>,
      );
    }

    return RoundScoreActiveSession(
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
      sortMode: PlayerSortMode.fromStorage(json['sortMode']),
      showSheet: (json['showSheet'] as bool?) ?? false,
      playerColors: PlayerColor.mapFromJson(json['playerColors']),
    );
  }
}