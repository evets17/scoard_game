import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/application/models/results/quick_score_player_result.dart';
import 'package:scoard_game/application/models/results/quick_score_result.dart';
import 'package:scoard_game/application/models/scoring/winner_rule.dart';
import 'package:scoard_game/application/services/scoring/load_setup_players.dart';
import 'package:scoard_game/infrastructure/memory/memory_player_repository.dart';
import 'package:scoard_game/infrastructure/memory/memory_session_repository.dart';
import 'package:scoard_game/infrastructure/memory/memory_setup_preferences_repository.dart';

void main() {
  late MemoryPlayerRepository players;
  late MemorySessionRepository sessions;
  late MemorySetupPreferencesRepository preferences;

  setUp(() {
    players = MemoryPlayerRepository.seeded();
    sessions = MemorySessionRepository.seeded();
    preferences = MemorySetupPreferencesRepository();
  });

  Future<SetupPlayers> load() => loadSetupPlayers(
        playerRepository: players,
        sessionRepository: sessions,
        setupPreferences: preferences,
      );

  QuickScorePlayerResult result(String playerId, String name) {
    return QuickScorePlayerResult(
      playerId: playerId,
      displayName: name,
      finalScore: 10,
      placement: 1,
      isTied: false,
    );
  }

  test('most recently played come first, then the rest by name', () async {
    // The seeded game in progress has Avery, Mina and Owen. Rio then
    // finishes a game later than that.
    await sessions.saveQuickScoreResult(
      result: QuickScoreResult(
        sessionId: 'later-game',
        templateId: 'quick-final-score-basic',
        templateDisplayName: 'Quick Score',
        winnerRule: WinnerRule.highestScoreWins,
        completedAt: DateTime.now().add(const Duration(hours: 1)),
        playerResults: [result('player-rio', 'Rio')],
      ),
      promptAnswers: const [],
      participantValues: const [],
    );

    final setup = await load();

    expect(
      setup.availablePlayers.map((player) => player.displayName),
      ['Rio', 'Avery', 'Mina', 'Owen', 'Jules'],
    );
  });

  test('remembers the last group and falls back when it is deleted', () async {
    final family = await players.createGroup(name: 'Family');
    await preferences.saveLastPlayerGroupId(family.id);

    expect((await load()).initialGroupId, family.id);

    await players.deleteGroup(groupId: family.id);

    expect((await load()).initialGroupId, isNull);
  });

  test('archived players are left out but keep their groups', () async {
    final family = await players.createGroup(name: 'Family');
    await players.setPlayerGroups(playerId: 'player-mina', groupIds: {family.id});
    await players.setArchived(playerId: 'player-jules', isArchived: true);

    final setup = await load();

    expect(
      setup.availablePlayers.map((player) => player.id),
      isNot(contains('player-jules')),
    );
    expect(
      setup.availablePlayers
          .singleWhere((player) => player.id == 'player-mina')
          .groupIds,
      {family.id},
    );
  });
}
