import 'package:scoard_game/application/models/app_summaries.dart';

abstract class GameRepository {
  Future<int> countGames();

  Future<List<GameSummary>> loadFeaturedGames({int limit = 4});
}