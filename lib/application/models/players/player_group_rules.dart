import 'package:scoard_game/application/models/players/player_group.dart';
import 'package:scoard_game/application/models/players/player_name_rules.dart';
import 'package:scoard_game/application/services/players/create_player.dart';

/// Names shown as built-in filters next to user groups.
const reservedPlayerGroupNames = {'all', 'archived'};

String createPlayerGroupId(String name, {DateTime? timestamp}) {
  final normalizedName = name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  final resolvedTimestamp = timestamp ?? DateTime.now();

  return 'group-$normalizedName-${resolvedTimestamp.microsecondsSinceEpoch}';
}

/// Returns the trimmed name, or throws [PlayerValidationException].
String validatePlayerGroupName({
  required String name,
  required Iterable<PlayerGroup> existingGroups,
  String? editingGroupId,
}) {
  final trimmedName = name.trim();

  if (trimmedName.isEmpty) {
    throw const PlayerValidationException('Group name is required.');
  }

  if (reservedPlayerGroupNames.contains(normalizePlayerName(trimmedName))) {
    throw PlayerValidationException(
      '"$trimmedName" is already used by the app. Try another name.',
    );
  }

  final isDuplicate = existingGroups.any(
    (group) =>
        group.id != editingGroupId &&
        normalizePlayerName(group.name) == normalizePlayerName(trimmedName),
  );
  if (isDuplicate) {
    throw PlayerValidationException(
      'A group named "$trimmedName" already exists.',
    );
  }

  return trimmedName;
}
