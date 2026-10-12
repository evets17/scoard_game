import 'package:scoard_game/application/models/sessions/quick_score_setup_model.dart';
import 'package:scoard_game/application/repositories/player_repository.dart';
import 'package:scoard_game/application/repositories/session_repository.dart';
import 'package:scoard_game/application/repositories/setup_preferences_repository.dart';
import 'package:scoard_game/application/services/scoring/load_setup_players.dart';
import 'package:scoard_game/core/scoring/built_in_templates/built_in_scoring_presets.dart';

const _quickFinalScorePresetId = 'quick-final-score-basic';

class LoadQuickScoreSetupModel {
  const LoadQuickScoreSetupModel({
    required this.playerRepository,
    required this.sessionRepository,
    required this.setupPreferences,
  });

  final PlayerRepository playerRepository;
  final SessionRepository sessionRepository;
  final SetupPreferencesRepository setupPreferences;

  Future<QuickScoreSetupModel> call({
    String presetId = _quickFinalScorePresetId,
  }) async {
    final setupPlayers = await loadSetupPlayers(
      playerRepository: playerRepository,
      sessionRepository: sessionRepository,
      setupPreferences: setupPreferences,
    );

    return QuickScoreSetupModel(
      preset: getBuiltInScoringPresetById(presetId),
      availablePlayers: setupPlayers.availablePlayers,
      groups: setupPlayers.groups,
      initialGroupId: setupPlayers.initialGroupId,
    );
  }
}
