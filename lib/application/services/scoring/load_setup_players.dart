import 'package:scoard_game/application/models/players/player_group.dart';
import 'package:scoard_game/application/models/sessions/quick_score_available_player.dart';
import 'package:scoard_game/application/repositories/player_repository.dart';
import 'package:scoard_game/application/repositories/session_repository.dart';
import 'package:scoard_game/application/repositories/setup_preferences_repository.dart';

typedef SetupPlayers = ({
  List<QuickScoreAvailablePlayer> availablePlayers,
  List<PlayerGroup> groups,
  String? initialGroupId,
});

/// Active players for game setup, most recently played first, then players
/// who haven't played yet in name order. Shared by every scoring style.
Future<SetupPlayers> loadSetupPlayers({
  required PlayerRepository playerRepository,
  required SessionRepository sessionRepository,
  required SetupPreferencesRepository setupPreferences,
}) async {
  final players = await playerRepository.loadPlayers();
  final lastPlayedAt = await sessionRepository.loadLastPlayedAtByPlayerId();
  final groups = (await playerRepository.loadGroups()).toList(growable: false)
    ..sort(
      (left, right) =>
          left.name.toLowerCase().compareTo(right.name.toLowerCase()),
    );
  final lastGroupId = await setupPreferences.loadLastPlayerGroupId();

  final activePlayers = players.where((player) => !player.isArchived).toList()
    ..sort((left, right) {
      final leftPlayed = lastPlayedAt[left.id];
      final rightPlayed = lastPlayedAt[right.id];
      if (leftPlayed != null && rightPlayed != null) {
        final comparison = rightPlayed.compareTo(leftPlayed);
        if (comparison != 0) {
          return comparison;
        }
      } else if (leftPlayed != null) {
        return -1;
      } else if (rightPlayed != null) {
        return 1;
      }

      return left.displayName
          .toLowerCase()
          .compareTo(right.displayName.toLowerCase());
    });

  return (
    availablePlayers: activePlayers
        .map(
          (player) => QuickScoreAvailablePlayer(
            id: player.id,
            displayName: player.displayName,
            groupIds: player.groupIds,
          ),
        )
        .toList(growable: false),
    groups: groups,
    initialGroupId: groups.any((group) => group.id == lastGroupId)
        ? lastGroupId
        : null,
  );
}
