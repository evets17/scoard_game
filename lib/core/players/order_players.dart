import 'package:scoard_game/application/models/scoring/winner_rule.dart';
import 'package:scoard_game/application/models/sessions/player_sort_mode.dart';
import 'package:scoard_game/application/models/sessions/quick_score_available_player.dart';

/// Returns [playersInPlayOrder] arranged for display.
///
/// Score sorting puts the leader first according to [winnerRule]. Ties keep
/// play order so rows never shuffle between equal scores.
List<QuickScoreAvailablePlayer> orderPlayersForDisplay(
  List<QuickScoreAvailablePlayer> playersInPlayOrder, {
  required PlayerSortMode sortMode,
  WinnerRule winnerRule = WinnerRule.highestScoreWins,
  Map<String, int> scoresByPlayerId = const {},
}) {
  if (sortMode == PlayerSortMode.playOrder) {
    return playersInPlayOrder;
  }

  final playOrderIndex = {
    for (var index = 0; index < playersInPlayOrder.length; index++)
      playersInPlayOrder[index].id: index,
  };

  int compare(QuickScoreAvailablePlayer left, QuickScoreAvailablePlayer right) {
    final comparison = switch (sortMode) {
      PlayerSortMode.playOrder => 0,
      PlayerSortMode.name => left.displayName
          .toLowerCase()
          .compareTo(right.displayName.toLowerCase()),
      PlayerSortMode.score => _compareScores(
          scoresByPlayerId[left.id] ?? 0,
          scoresByPlayerId[right.id] ?? 0,
          winnerRule,
        ),
    };

    if (comparison != 0) {
      return comparison;
    }

    return playOrderIndex[left.id]!.compareTo(playOrderIndex[right.id]!);
  }

  return [...playersInPlayOrder]..sort(compare);
}

/// Moves the item at [oldIndex] to [newIndex] using the index convention of
/// Flutter's reorderable lists.
List<T> moveListItem<T>(List<T> items, int oldIndex, int newIndex) {
  final adjustedIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
  final reordered = [...items];
  final item = reordered.removeAt(oldIndex);
  reordered.insert(adjustedIndex, item);
  return reordered;
}

int _compareScores(int left, int right, WinnerRule winnerRule) {
  return switch (winnerRule) {
    WinnerRule.highestScoreWins => right.compareTo(left),
    WinnerRule.lowestScoreWins => left.compareTo(right),
  };
}
