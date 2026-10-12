import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/application/models/players/player_group.dart';
import 'package:scoard_game/application/models/players/player_group_rules.dart';
import 'package:scoard_game/application/services/players/create_player.dart';

void main() {
  final family = PlayerGroup(
    id: 'group-family',
    name: 'Family',
    createdAt: DateTime(2026, 10, 1),
  );

  String validate(String name, {String? editingGroupId}) {
    return validatePlayerGroupName(
      name: name,
      existingGroups: [family],
      editingGroupId: editingGroupId,
    );
  }

  test('trims valid names', () {
    expect(validate('  Friends '), 'Friends');
  });

  test('rejects empty, reserved, and duplicate names', () {
    expect(() => validate('   '), throwsA(isA<PlayerValidationException>()));
    expect(() => validate('All'), throwsA(isA<PlayerValidationException>()));
    expect(() => validate('archived'), throwsA(isA<PlayerValidationException>()));
    expect(() => validate('family'), throwsA(isA<PlayerValidationException>()));
  });

  test('a group may keep its own name when renamed', () {
    expect(validate('FAMILY', editingGroupId: 'group-family'), 'FAMILY');
  });
}
