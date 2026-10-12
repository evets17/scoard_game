import 'package:scoard_game/application/repositories/game_repository.dart';
import 'package:scoard_game/application/repositories/player_repository.dart';
import 'package:scoard_game/application/repositories/session_repository.dart';
import 'package:scoard_game/application/services/load_home_shell_model.dart';
import 'package:scoard_game/application/services/players/archive_player.dart';
import 'package:scoard_game/application/services/players/create_player.dart';
import 'package:scoard_game/application/services/players/create_player_group.dart';
import 'package:scoard_game/application/services/players/delete_player_group.dart';
import 'package:scoard_game/application/services/players/load_players_screen_model.dart';
import 'package:scoard_game/application/services/players/rename_player.dart';
import 'package:scoard_game/application/services/players/rename_player_group.dart';
import 'package:scoard_game/application/services/players/set_player_groups.dart';
import 'package:scoard_game/application/services/players/unarchive_player.dart';
import 'package:scoard_game/application/services/scoring/load_quick_score_setup_model.dart';
import 'package:scoard_game/application/services/scoring/load_round_score_setup_model.dart';
import 'package:scoard_game/application/services/scoring/load_score_game_choices.dart';
import 'package:scoard_game/application/services/scoring/remember_setup_player_group.dart';
import 'package:scoard_game/application/services/sessions/delete_active_session.dart';
import 'package:scoard_game/application/services/sessions/load_quick_score_active_session.dart';
import 'package:scoard_game/application/services/sessions/load_round_score_active_session.dart';
import 'package:scoard_game/application/services/sessions/save_quick_score_active_session.dart';
import 'package:scoard_game/application/services/sessions/save_round_score_active_session.dart';
import 'package:scoard_game/application/services/sessions/save_round_score_session.dart';
import 'package:scoard_game/application/services/sessions/save_quick_score_session.dart';
import 'package:scoard_game/core/templates/template_catalog.dart';
import 'package:scoard_game/ui/settings/stay_awake_controller.dart';
import 'package:scoard_game/ui/theme/app_theme_controller.dart';

class AppEnvironment {
  AppEnvironment({
    required this.playerRepository,
    required this.gameRepository,
    required this.sessionRepository,
    required this.loadHomeShellModel,
    required this.themeController,
    required this.stayAwakeController,
    required this.templateCatalog,
    required this.loadScoreGameChoices,
    required this.loadPlayersScreenModel,
    required this.createPlayer,
    required this.renamePlayer,
    required this.archivePlayer,
    required this.unarchivePlayer,
    required this.createPlayerGroup,
    required this.renamePlayerGroup,
    required this.deletePlayerGroup,
    required this.setPlayerGroups,
    required this.rememberSetupPlayerGroup,
    required this.loadQuickScoreSetupModel,
    required this.saveQuickScoreSession,
    required this.loadRoundScoreSetupModel,
    required this.saveRoundScoreSession,
    required this.loadQuickScoreActiveSession,
    required this.saveQuickScoreActiveSession,
    required this.loadRoundScoreActiveSession,
    required this.saveRoundScoreActiveSession,
    required this.deleteActiveSession,
  });

  final PlayerRepository playerRepository;
  final GameRepository gameRepository;
  final SessionRepository sessionRepository;
  final LoadHomeShellModel loadHomeShellModel;
  final AppThemeController themeController;
  final StayAwakeController stayAwakeController;
  final TemplateCatalog templateCatalog;
  final LoadScoreGameChoices loadScoreGameChoices;
  final LoadPlayersScreenModel loadPlayersScreenModel;
  final CreatePlayer createPlayer;
  final RenamePlayer renamePlayer;
  final ArchivePlayer archivePlayer;
  final UnarchivePlayer unarchivePlayer;
  final CreatePlayerGroup createPlayerGroup;
  final RenamePlayerGroup renamePlayerGroup;
  final DeletePlayerGroup deletePlayerGroup;
  final SetPlayerGroups setPlayerGroups;
  final RememberSetupPlayerGroup rememberSetupPlayerGroup;
  final LoadQuickScoreSetupModel loadQuickScoreSetupModel;
  final SaveQuickScoreSession saveQuickScoreSession;
  final LoadRoundScoreSetupModel loadRoundScoreSetupModel;
  final SaveRoundScoreSession saveRoundScoreSession;
  final LoadQuickScoreActiveSession loadQuickScoreActiveSession;
  final SaveQuickScoreActiveSession saveQuickScoreActiveSession;
  final LoadRoundScoreActiveSession loadRoundScoreActiveSession;
  final SaveRoundScoreActiveSession saveRoundScoreActiveSession;
  final DeleteActiveSession deleteActiveSession;
}