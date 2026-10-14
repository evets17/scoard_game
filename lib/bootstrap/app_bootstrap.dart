import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scoard_game/application/repositories/online_template_repository.dart';
import 'package:scoard_game/application/repositories/player_repository.dart';
import 'package:scoard_game/application/repositories/session_repository.dart';
import 'package:scoard_game/application/repositories/setup_preferences_repository.dart';
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
import 'package:scoard_game/application/services/templates/online_templates.dart';
import 'package:scoard_game/bootstrap/app_environment.dart';
import 'package:scoard_game/core/templates/template_catalog.dart';
import 'package:scoard_game/infrastructure/memory/memory_game_repository.dart';
import 'package:scoard_game/infrastructure/memory/memory_online_template_cache.dart';
import 'package:scoard_game/infrastructure/memory/memory_player_repository.dart';
import 'package:scoard_game/infrastructure/memory/memory_session_repository.dart';
import 'package:scoard_game/infrastructure/memory/memory_setup_preferences_repository.dart';
import 'package:scoard_game/infrastructure/memory/memory_template_source_preferences.dart';
import 'package:scoard_game/infrastructure/persistence/db/app_database.dart';
import 'package:scoard_game/infrastructure/persistence/preferences/setup_preference_store.dart';
import 'package:scoard_game/infrastructure/persistence/preferences/stay_awake_preference_store.dart';
import 'package:scoard_game/infrastructure/persistence/preferences/template_source_preference_store.dart';
import 'package:scoard_game/infrastructure/persistence/preferences/theme_preference_store.dart';
import 'package:scoard_game/infrastructure/persistence/repositories/persistent_player_repository.dart';
import 'package:scoard_game/infrastructure/persistence/repositories/persistent_session_repository.dart';
import 'package:scoard_game/infrastructure/templates/bundled_template_files.dart';
import 'package:scoard_game/infrastructure/templates/file_online_template_cache.dart';
import 'package:scoard_game/infrastructure/templates/http_template_downloader.dart';
import 'package:scoard_game/ui/settings/stay_awake_controller.dart';
import 'package:scoard_game/ui/theme/app_theme_controller.dart';

class AppBootstrap {
  /// [templateDownloader] and [templateSourcePreferences] let tests replace
  /// the network and the online template settings.
  static Future<AppEnvironment> initialize({
    bool usePersistentStorage = false,
    TemplateCatalog? templateCatalog,
    TemplateDownloader? templateDownloader,
    TemplateSourcePreferences? templateSourcePreferences,
  }) async {
    await Future<void>.microtask(() {});

    final catalog = templateCatalog ?? await _loadTemplateCatalog();
    final OnlineTemplateCache onlineTemplateCache;
    final TemplateSourcePreferences sourcePreferences;
    final gameRepository = MemoryGameRepository.seeded();
    final PlayerRepository playerRepository;
    final SessionRepository sessionRepository;
    final AppThemeController themeController;
    final StayAwakeController stayAwakeController;
    final SetupPreferencesRepository setupPreferences;

    if (usePersistentStorage) {
      final appDatabase = AppDatabase();
      final themePreferenceStore = await ThemePreferenceStore.create();
      final stayAwakePreferenceStore = await StayAwakePreferenceStore.create();
      setupPreferences = await SetupPreferenceStore.create();
      sourcePreferences = templateSourcePreferences ??
          await TemplateSourcePreferenceStore.create();
      onlineTemplateCache = FileOnlineTemplateCache(
        Directory(
          '${(await getApplicationSupportDirectory()).path}/online_templates',
        ),
      );

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
      setupPreferences = MemorySetupPreferencesRepository();
      sourcePreferences =
          templateSourcePreferences ?? MemoryTemplateSourcePreferences();
      onlineTemplateCache = MemoryOnlineTemplateCache();
    }

    // Off by default in debug builds, so an older online copy never hides a
    // template being edited locally.
    final onlineTemplates = OnlineTemplates(
      catalog: catalog,
      downloader: templateDownloader ?? HttpTemplateDownloader(),
      cache: onlineTemplateCache,
      preferences: sourcePreferences,
      enabledByDefault: usePersistentStorage && !kDebugMode,
    );
    await onlineTemplates.loadSaved();

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
      templateCatalog: catalog,
      onlineTemplates: onlineTemplates,
      loadScoreGameChoices: LoadScoreGameChoices(
        templateCatalog: catalog,
        sessionRepository: sessionRepository,
      ),
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
      rememberSetupPlayerGroup: RememberSetupPlayerGroup(
        setupPreferences: setupPreferences,
      ),
      loadQuickScoreSetupModel: LoadQuickScoreSetupModel(
        templateCatalog: catalog,
        playerRepository: playerRepository,
        sessionRepository: sessionRepository,
        setupPreferences: setupPreferences,
      ),
      saveQuickScoreSession: SaveQuickScoreSession(
        sessionRepository: sessionRepository,
      ),
      loadRoundScoreSetupModel: LoadRoundScoreSetupModel(
        templateCatalog: catalog,
        playerRepository: playerRepository,
        sessionRepository: sessionRepository,
        setupPreferences: setupPreferences,
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
/// Loads the bundled scoring templates. A broken template stops a debug
/// build so it gets fixed; release builds leave it out and carry on.
Future<TemplateCatalog> _loadTemplateCatalog() async {
  final result = loadTemplateCatalog(await loadBundledTemplateFiles(rootBundle));

  if (result.hasProblems) {
    final message = 'Invalid scoring templates:\n${result.describeProblems()}';
    if (kDebugMode) {
      throw StateError(message);
    }
    debugPrint(message);
  }

  return result.catalog;
}
