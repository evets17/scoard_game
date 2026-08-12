import 'package:scoard_game/application/models/sessions/quick_score_available_player.dart';
import 'package:scoard_game/application/models/sessions/quick_score_setup_model.dart';
import 'package:scoard_game/application/repositories/player_repository.dart';
import 'package:scoard_game/core/scoring/built_in_templates/built_in_scoring_presets.dart';

const _quickFinalScorePresetId = 'quick-final-score-basic';

class LoadQuickScoreSetupModel {
  const LoadQuickScoreSetupModel({required this.playerRepository});

  final PlayerRepository playerRepository;

  Future<QuickScoreSetupModel> call({
    String presetId = _quickFinalScorePresetId,
  }) async {
    final players = await playerRepository.loadPlayers();

    final availablePlayers = players
        .where((player) => !player.isArchived)
        .map(
          (player) => QuickScoreAvailablePlayer(
            id: player.id,
            displayName: player.displayName,
          ),
        )
        .toList(growable: false)
      ..sort((left, right) => left.displayName.compareTo(right.displayName));

    return QuickScoreSetupModel(
      preset: getBuiltInScoringPresetById(presetId),
      availablePlayers: availablePlayers,
    );
  }
}