import 'package:scoard_game/application/models/home_shell_model.dart';
import 'package:scoard_game/application/repositories/player_repository.dart';
import 'package:scoard_game/application/repositories/session_repository.dart';
import 'package:scoard_game/ui/navigation/app_routes.dart';

class LoadHomeShellModel {
  const LoadHomeShellModel({
    required this.playerRepository,
    required this.sessionRepository,
  });

  final PlayerRepository playerRepository;
  final SessionRepository sessionRepository;

  Future<HomeShellModel> call() async {
    final playersFuture = playerRepository.loadPlayers();
    final activeSessionsFuture = sessionRepository.loadActiveSessions(limit: 3);

    await playersFuture;
    final activeSessions = await activeSessionsFuture;

    final primaryActions = <HomeActionModel>[];

    if (activeSessions.length == 1) {
      final activeSession = activeSessions.single;

      primaryActions.add(
        HomeActionModel(
          route: AppRoutes.activeGames,
          title: 'Resume ${activeSession.gameName}',
          icon: 'resume',
          arguments: true,
        ),
      );
    } else if (activeSessions.length > 1) {
      primaryActions.add(
        HomeActionModel(
          route: AppRoutes.activeGames,
          title: 'Active Games',
          icon: 'resume',
        ),
      );
    }

    primaryActions.add(
      const HomeActionModel(
        route: AppRoutes.newGame,
        title: 'Score a Game',
        icon: 'new-game',
      ),
    );

    primaryActions.add(
      HomeActionModel(
        route: AppRoutes.players,
        title: 'Players',
        icon: 'players',
      ),
    );

    primaryActions.add(
      const HomeActionModel(
        route: AppRoutes.playStats,
        title: 'Play Stats',
        icon: 'stats',
      ),
    );

    return HomeShellModel(
      appName: 'Scoard Game',
      tagline: 'Fast scorekeeping for game night.',
      primaryActions: primaryActions,
    );
  }
}