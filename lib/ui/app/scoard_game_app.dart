import 'package:flutter/material.dart';
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
              ),
            AppRoutes.players: (_) => PlayersScreen(
                  loadPlayersScreenModel: environment.loadPlayersScreenModel,
                  createPlayer: environment.createPlayer,
                  renamePlayer: environment.renamePlayer,
                  archivePlayer: environment.archivePlayer,
                  unarchivePlayer: environment.unarchivePlayer,
                ),
            AppRoutes.newGame: (_) => const ScoreGameScreen(),
            AppRoutes.quickScore: (_) => QuickScoreFlowScreen(
                  loadQuickScoreSetupModel: environment.loadQuickScoreSetupModel,
                  createPlayer: environment.createPlayer,
                  saveQuickScoreSession: environment.saveQuickScoreSession,
                saveQuickScoreActiveSession:
                  environment.saveQuickScoreActiveSession,
                deleteActiveSession: environment.deleteActiveSession,
                ),
            AppRoutes.roundScore: (_) => RoundScoreFlowScreen(
                  loadRoundScoreSetupModel: environment.loadRoundScoreSetupModel,
                  createPlayer: environment.createPlayer,
                  saveRoundScoreSession: environment.saveRoundScoreSession,
                saveRoundScoreActiveSession:
                  environment.saveRoundScoreActiveSession,
                deleteActiveSession: environment.deleteActiveSession,
                ),
            AppRoutes.playStats: (_) => const PlaceholderScreen(
                  title: 'Play Stats',
                  description:
                      'See past sessions, winners, and simple trends from your game nights.',
                  callout: 'This area is coming soon.',
                ),
            AppRoutes.settings: (_) => SettingsScreen(
                  themeController: environment.themeController,
                ),
          },
          initialRoute: AppRoutes.home,
        );
      },
    );
  }
}