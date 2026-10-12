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
import 'package:scoard_game/application/services/sessions/delete_active_session.dart';
import 'package:scoard_game/application/services/sessions/load_quick_score_active_session.dart';
import 'package:scoard_game/application/services/sessions/load_round_score_active_session.dart';
import 'package:scoard_game/application/services/sessions/save_quick_score_active_session.dart';
import 'package:scoard_game/application/services/sessions/save_round_score_active_session.dart';
import 'package:scoard_game/application/services/sessions/save_round_score_session.dart';
import 'package:scoard_game/application/services/sessions/save_quick_score_session.dart';
import 'package:scoard_game/bootstrap/app_environment.dart';
import 'package:scoard_game/infrastructure/memory/memory_game_repository.dart';
import 'package:scoard_game/infrastructure/memory/memory_player_repository.dart';
import 'package:scoard_game/infrastructure/memory/memory_session_repository.dart';
import 'package:scoard_game/infrastructure/persistence/db/app_database.dart';
import 'package:scoard_game/infrastructure/persistence/preferences/stay_awake_preference_store.dart';
import 'package:scoard_game/infrastructure/persistence/preferences/theme_preference_store.dart';
import 'package:scoard_game/infrastructure/persistence/repositories/persistent_player_repository.dart';
import 'package:scoard_game/infrastructure/persistence/repositories/persistent_session_repository.dart';
import 'package:scoard_game/ui/settings/stay_awake_controller.dart';
import 'package:scoard_game/ui/theme/app_theme_controller.dart';

class AppBootstrap {
  static Future<AppEnvironment> initialize({
    bool usePersistentStorage = false,
  }) async {
    await Future<void>.microtask(() {});

    final gameRepository = MemoryGameRepository.seeded();
    final PlayerRepository playerRepository;
    final SessionRepository sessionRepository;
    final AppThemeController themeController;
    final StayAwakeController stayAwakeController;

    if (usePersistentStorage) {
      final appDatabase = AppDatabase();
      final themePreferenceStore = await ThemePreferenceStore.create();
      final stayAwakePreferenceStore = await StayAwakePreferenceStore.create();

      playerRepository = PersistentPlayerRepository(appDatabase);
      sessionRepository = PersistentSessionRepository(appDatabase);
      themeController = AppThemeController(
        initialChoice: await themePreferenceStore.loadThemeChoice(),
        onThemeChanged: themePreferenceStore.saveThemeChoice,
      );
      stayAwakeController = StayAwakeController(
        initialEnabled: stayAwakePreferenceStore.loadStayAwake(),
        onEnabledChanged: stayAwakePreferenceStore.saveStayAwake,
      );
    } else {
      playerRepository = MemoryPlayerRepository.seeded();
      sessionRepository = MemorySessionRepository.seeded();
      themeController = AppThemeController();
      stayAwakeController = StayAwakeController();
    }

    return AppEnvironment(
      playerRepository: playerRepository,
      gameRepository: gameRepository,
      sessionRepository: sessionRepository,
      loadHomeShellModel: LoadHomeShellModel(
        playerRepository: playerRepository,
        sessionRepository: sessionRepository,
      ),
      themeController: themeController,
      stayAwakeController: stayAwakeController,
      loadPlayersScreenModel: LoadPlayersScreenModel(
        playerRepository: playerRepository,
      ),
      createPlayer: CreatePlayer(playerRepository: playerRepository),
      renamePlayer: RenamePlayer(playerRepository: playerRepository),
      archivePlayer: ArchivePlayer(playerRepository: playerRepository),
      unarchivePlayer: UnarchivePlayer(playerRepository: playerRepository),
      createPlayerGroup: CreatePlayerGroup(playerRepository: playerRepository),
      renamePlayerGroup: RenamePlayerGroup(playerRepository: playerRepository),
      deletePlayerGroup: DeletePlayerGroup(playerRepository: playerRepository),
      setPlayerGroups: SetPlayerGroups(playerRepository: playerRepository),
      loadQuickScoreSetupModel: LoadQuickScoreSetupModel(
        playerRepository: playerRepository,
      ),
      saveQuickScoreSession: SaveQuickScoreSession(
        sessionRepository: sessionRepository,
      ),
      loadRoundScoreSetupModel: LoadRoundScoreSetupModel(
        playerRepository: playerRepository,
      ),
      saveRoundScoreSession: SaveRoundScoreSession(
        sessionRepository: sessionRepository,
      ),
      loadQuickScoreActiveSession: LoadQuickScoreActiveSession(
        sessionRepository: sessionRepository,
      ),
      saveQuickScoreActiveSession: SaveQuickScoreActiveSession(
        sessionRepository: sessionRepository,
      ),
      loadRoundScoreActiveSession: LoadRoundScoreActiveSession(
        sessionRepository: sessionRepository,
      ),
      saveRoundScoreActiveSession: SaveRoundScoreActiveSession(
        sessionRepository: sessionRepository,
      ),
      deleteActiveSession: DeleteActiveSession(
        sessionRepository: sessionRepository,
      ),
    );
  }
}