import 'package:flutter/material.dart';
import 'package:scoard_game/application/models/sessions/scoring_session_start_configuration.dart';
import 'package:scoard_game/bootstrap/app_environment.dart';
import 'package:scoard_game/ui/home/home_screen.dart';
import 'package:scoard_game/ui/active_games/active_games_screen.dart';
import 'package:scoard_game/ui/navigation/app_routes.dart';
import 'package:scoard_game/ui/navigation/placeholder_screen.dart';
import 'package:scoard_game/ui/players/players_screen.dart';
import 'package:scoard_game/ui/quick_score/quick_score_flow_screen.dart';
import 'package:scoard_game/ui/round_score/round_score_flow_screen.dart';
import 'package:scoard_game/ui/quick_score/score_game_screen.dart';
import 'package:scoard_game/ui/settings/settings_screen.dart';
import 'package:scoard_game/ui/theme/app_theme.dart';

class ScoardGameApp extends StatelessWidget {
  const ScoardGameApp({
    required this.environment,
    super.key,
  });

  final AppEnvironment environment;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: environment.themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Scoard Game',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(
            palette: environment.themeController.selectedPalette,
          ),
          routes: {
            AppRoutes.home: (_) => HomeScreen(
                  loadHomeShellModel: environment.loadHomeShellModel,
                ),
            AppRoutes.activeGames: (_) => ActiveGamesScreen(
                sessionRepository: environment.sessionRepository,
                loadQuickScoreActiveSession:
                  environment.loadQuickScoreActiveSession,
                saveQuickScoreActiveSession:
                  environment.saveQuickScoreActiveSession,
                loadQuickScoreSetupModel:
                  environment.loadQuickScoreSetupModel,
                saveQuickScoreSession: environment.saveQuickScoreSession,
                loadRoundScoreActiveSession:
                  environment.loadRoundScoreActiveSession,
                saveRoundScoreActiveSession:
                  environment.saveRoundScoreActiveSession,
                loadRoundScoreSetupModel:
                  environment.loadRoundScoreSetupModel,
                saveRoundScoreSession: environment.saveRoundScoreSession,
                deleteActiveSession: environment.deleteActiveSession,
                createPlayer: environment.createPlayer,
                renamePlayer: environment.renamePlayer,
                stayAwakeController: environment.stayAwakeController,
              ),
            AppRoutes.players: (_) => PlayersScreen(
                  loadPlayersScreenModel: environment.loadPlayersScreenModel,
                  createPlayer: environment.createPlayer,
                  renamePlayer: environment.renamePlayer,
                  archivePlayer: environment.archivePlayer,
                  unarchivePlayer: environment.unarchivePlayer,
                  createPlayerGroup: environment.createPlayerGroup,
                  renamePlayerGroup: environment.renamePlayerGroup,
                  deletePlayerGroup: environment.deletePlayerGroup,
                  setPlayerGroups: environment.setPlayerGroups,
                ),
            AppRoutes.newGame: (_) => const ScoreGameScreen(),
            AppRoutes.playStats: (_) => const PlaceholderScreen(
                  title: 'Play Stats',
                  description:
                      'See past sessions, winners, and simple trends from your game nights.',
                  callout: 'This area is coming soon.',
                ),
            AppRoutes.settings: (_) => SettingsScreen(
                  themeController: environment.themeController,
                  stayAwakeController: environment.stayAwakeController,
                ),
          },
          onGenerateRoute: (settings) {
            final arguments = settings.arguments;

            switch (settings.name) {
              case AppRoutes.quickScore:
                final configuration = arguments is ScoringSessionStartConfiguration
                    ? arguments
                    : const ScoringSessionStartConfiguration(
                        presetId: 'quick-final-score-basic',
                      );
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (_) => QuickScoreFlowScreen(
                    loadQuickScoreSetupModel: environment.loadQuickScoreSetupModel,
                    createPlayer: environment.createPlayer,
                    renamePlayer: environment.renamePlayer,
                    stayAwakeController: environment.stayAwakeController,
                    saveQuickScoreSession: environment.saveQuickScoreSession,
                    saveQuickScoreActiveSession:
                        environment.saveQuickScoreActiveSession,
                    deleteActiveSession: environment.deleteActiveSession,
                    initialPresetId: configuration.presetId,
                    initialPromptAnswers: configuration.promptAnswers,
                  ),
                );
              case AppRoutes.roundScore:
                final configuration = arguments is ScoringSessionStartConfiguration
                    ? arguments
                    : const ScoringSessionStartConfiguration(
                        presetId: 'round-score-basic',
                      );
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (_) => RoundScoreFlowScreen(
                    loadRoundScoreSetupModel: environment.loadRoundScoreSetupModel,
                    createPlayer: environment.createPlayer,
                    renamePlayer: environment.renamePlayer,
                    stayAwakeController: environment.stayAwakeController,
                    saveRoundScoreSession: environment.saveRoundScoreSession,
                    saveRoundScoreActiveSession:
                        environment.saveRoundScoreActiveSession,
                    deleteActiveSession: environment.deleteActiveSession,
                    initialPresetId: configuration.presetId,
                    initialPromptAnswers: configuration.promptAnswers,
                  ),
                );
            }

            return null;
          },
          initialRoute: AppRoutes.home,
        );
      },
    );
  }
}