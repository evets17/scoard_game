import 'package:scoard_game/application/models/sessions/quick_score_participant_values.dart';

class RoundScoreRoundValues {
  const RoundScoreRoundValues({
    required this.roundNumber,
    required this.participantValues,
  });

  final int roundNumber;
  final List<QuickScoreParticipantValues> participantValues;
}