import 'package:scoard_game/application/models/app_summaries.dart';
import 'package:scoard_game/application/repositories/game_repository.dart';

class MemoryGameRepository implements GameRepository {
  MemoryGameRepository._(this._games);

  factory MemoryGameRepository.seeded() {
    return MemoryGameRepository._([
      const GameSummary(
        id: 'game-qwinto',
        name: 'Qwinto',
        scoringStyle: 'End-game tally',
      ),
      const GameSummary(
        id: 'game-skyjo',
        name: 'Skyjo',
        scoringStyle: 'Running total',
      ),
      const GameSummary(
        id: 'game-azul',
        name: 'Azul',
        scoringStyle: 'Round plus final bonus',
      ),
      const GameSummary(
        id: 'game-jaipur',
        name: 'Jaipur',
        scoringStyle: 'Result-only quick score',
      ),
    ]);
  }

  final List<GameSummary> _games;

  @override
  Future<int> countGames() async => _games.length;

  @override
  Future<List<GameSummary>> loadFeaturedGames({int limit = 4}) async {
    return _games.take(limit).toList(growable: false);
  }
}