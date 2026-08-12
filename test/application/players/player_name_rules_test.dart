import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/application/models/players/player_name_rules.dart';

void main() {
  test('partial player-name matching works in both directions', () {
    expect(
      hasPartialPlayerNameMatch(query: 'Josh', existingName: 'Josh (Brother)'),
      isTrue,
    );
    expect(
      hasPartialPlayerNameMatch(query: 'Josh (Brother)', existingName: 'Josh'),
      isTrue,
    );
    expect(
      hasPartialPlayerNameMatch(query: 'Avery', existingName: 'Mina'),
      isFalse,
    );
  });
}