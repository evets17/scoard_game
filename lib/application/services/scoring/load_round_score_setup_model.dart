import 'package:scoard_game/application/models/sessions/round_score_setup_model.dart';
import 'package:scoard_game/application/repositories/player_repository.dart';
import 'package:scoard_game/application/repositories/session_repository.dart';
import 'package:scoard_game/application/repositories/setup_preferences_repository.dart';
import 'package:scoard_game/application/services/scoring/load_setup_players.dart';
import 'package:scoard_game/core/scoring/built_in_templates/built_in_scoring_presets.dart';

const _roundScorePresetId = 'round-score-basic';

class LoadRoundScoreSetupModel {
  const LoadRoundScoreSetupModel({
    required this.playerRepository,
    required this.sessionRepository,
    required this.setupPreferences,
  });

  final PlayerRepository playerRepository;
  final SessionRepository sessionRepository;
  final SetupPreferencesRepository setupPreferences;

  Future<RoundScoreSetupModel> call({
    String presetId = _roundScorePresetId,
  }) async {
    final setupPlayers = await loadSetupPlayers(
      playerRepository: playerRepository,
      sessionRepository: sessionRepository,
      setupPreferences: setupPreferences,
    );

    return RoundScoreSetupModel(
      preset: getBuiltInScoringPresetById(presetId),
      availablePlayers: setupPlayers.availablePlayers,
      groups: setupPlayers.groups,
      initialGroupId: setupPlayers.initialGroupId,
    );
  }
}
