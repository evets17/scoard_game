import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/application/models/scoring/winner_rule.dart';
import 'package:scoard_game/application/models/sessions/player_sort_mode.dart';
import 'package:scoard_game/application/models/sessions/quick_score_available_player.dart';
import 'package:scoard_game/core/players/order_players.dart';

void main() {
  const players = [
    QuickScoreAvailablePlayer(id: 'rio', displayName: 'Rio'),
    QuickScoreAvailablePlayer(id: 'avery', displayName: 'avery'),
    QuickScoreAvailablePlayer(id: 'mina', displayName: 'Mina'),
  ];

  List<String> idsOf(List<QuickScoreAvailablePlayer> ordered) =>
      ordered.map((player) => player.id).toList();

  test('play order keeps players as entered', () {
    final ordered = orderPlayersForDisplay(
      players,
      sortMode: PlayerSortMode.playOrder,
    );

    expect(idsOf(ordered), ['rio', 'avery', 'mina']);
  });

  test('name order ignores case', () {
    final ordered = orderPlayersForDisplay(
      players,
      sortMode: PlayerSortMode.name,
    );

    expect(idsOf(ordered), ['avery', 'mina', 'rio']);
  });

  test('score order puts the leader first and keeps play order for ties', () {
    const scores = {'rio': 10, 'avery': 25, 'mina': 10};

    final highWins = orderPlayersForDisplay(
      players,
      sortMode: PlayerSortMode.score,
      scoresByPlayerId: scores,
    );
    final lowWins = orderPlayersForDisplay(
      players,
      sortMode: PlayerSortMode.score,
      winnerRule: WinnerRule.lowestScoreWins,
      scoresByPlayerId: scores,
    );

    expect(idsOf(highWins), ['avery', 'rio', 'mina']);
    expect(idsOf(lowWins), ['rio', 'mina', 'avery']);
  });

  test('moveListItem follows reorderable list index rules', () {
    expect(moveListItem(['a', 'b', 'c'], 0, 3), ['b', 'c', 'a']);
    expect(moveListItem(['a', 'b', 'c'], 2, 0), ['c', 'a', 'b']);
  });

  test('unknown stored sort modes fall back to play order', () {
    expect(PlayerSortMode.fromStorage('score'), PlayerSortMode.score);
    expect(PlayerSortMode.fromStorage(null), PlayerSortMode.playOrder);
    expect(PlayerSortMode.fromStorage('bogus'), PlayerSortMode.playOrder);
  });
}
