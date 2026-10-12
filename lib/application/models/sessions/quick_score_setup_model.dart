import 'package:scoard_game/application/models/players/player_group.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/application/models/sessions/quick_score_available_player.dart';

class QuickScoreSetupModel {
  const QuickScoreSetupModel({
    required this.preset,
    required this.availablePlayers,
    this.groups = const [],
    this.initialGroupId,
  });

  final ScoringPreset preset;

  /// Active players, most recently played first, then the rest A–Z.
  final List<QuickScoreAvailablePlayer> availablePlayers;

  /// User-made groups, sorted by name.
  final List<PlayerGroup> groups;

  /// The group filter picked last time, if it still exists.
  final String? initialGroupId;
}
