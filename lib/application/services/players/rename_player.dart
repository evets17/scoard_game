import 'package:scoard_game/application/models/players/player_name_rules.dart';
import 'package:scoard_game/application/models/players/player_record.dart';
import 'package:scoard_game/application/repositories/player_repository.dart';
import 'package:scoard_game/application/services/players/create_player.dart';

class RenamePlayer {
  const RenamePlayer({required this.playerRepository});

  final PlayerRepository playerRepository;

  Future<PlayerRecord> call({
    required String playerId,
    required String displayName,
  }) async {
    final normalizedName = displayName.trim();

    if (normalizedName.isEmpty) {
      throw const PlayerValidationException('Player name is required.');
    }

    final existingPlayers = await playerRepository.loadPlayers();
    final duplicatePlayer = existingPlayers.where((player) {
      return player.id != playerId &&
          normalizePlayerName(player.displayName) ==
              normalizePlayerName(normalizedName);
    }).firstOrNull;

    if (duplicatePlayer != null) {
      final archiveHint = duplicatePlayer.isArchived
          ? ' That player is currently archived.'
          : '';

      throw PlayerValidationException(
        'A player named "$normalizedName" already exists.$archiveHint Try a more specific name.',
      );
    }

    return playerRepository.renamePlayer(
      playerId: playerId,
      displayName: normalizedName,
    );
  }
}