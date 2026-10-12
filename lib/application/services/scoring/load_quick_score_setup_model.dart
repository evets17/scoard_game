import 'package:scoard_game/application/models/sessions/quick_score_setup_model.dart';
import 'package:scoard_game/application/repositories/player_repository.dart';
import 'package:scoard_game/application/repositories/session_repository.dart';
import 'package:scoard_game/application/repositories/setup_preferences_repository.dart';
import 'package:scoard_game/application/services/scoring/load_setup_players.dart';
import 'package:scoard_game/core/templates/template_catalog.dart';

class LoadQuickScoreSetupModel {
  const LoadQuickScoreSetupModel({
    required this.templateCatalog,
    required this.playerRepository,
    required this.sessionRepository,
    required this.setupPreferences,
  });

  final TemplateCatalog templateCatalog;
  final PlayerRepository playerRepository;
  final SessionRepository sessionRepository;
  final SetupPreferencesRepository setupPreferences;

  Future<QuickScoreSetupModel> call({required String presetId}) async {
    final setupPlayers = await loadSetupPlayers(
      playerRepository: playerRepository,
      sessionRepository: sessionRepository,
      setupPreferences: setupPreferences,
    );

    return QuickScoreSetupModel(
      preset: templateCatalog.byId(presetId),
      availablePlayers: setupPlayers.availablePlayers,
      groups: setupPlayers.groups,
      initialGroupId: setupPlayers.initialGroupId,
    );
  }
}
