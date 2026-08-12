import 'package:scoard_game/application/models/players/player_name_rules.dart';
import 'package:scoard_game/application/models/players/player_record.dart';
import 'package:scoard_game/application/repositories/player_repository.dart';

class CreatePlayer {
  const CreatePlayer({required this.playerRepository});

  final PlayerRepository playerRepository;

  Future<PlayerRecord> call({required String displayName}) async {
    final normalizedName = displayName.trim();

    if (normalizedName.isEmpty) {
      throw const PlayerValidationException('Player name is required.');
    }

    final existingPlayers = await playerRepository.loadPlayers();
    final duplicatePlayer = existingPlayers.where((player) {
      return normalizePlayerName(player.displayName) ==
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

    return playerRepository.createPlayer(displayName: normalizedName);
  }
}

class PlayerValidationException implements Exception {
  const PlayerValidationException(this.message);

  final String message;
}