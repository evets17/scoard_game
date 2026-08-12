import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/application/models/sessions/quick_score_available_player.dart';

class QuickScoreSetupModel {
  const QuickScoreSetupModel({
    required this.preset,
    required this.availablePlayers,
  });

  final ScoringPreset preset;
  final List<QuickScoreAvailablePlayer> availablePlayers;
}