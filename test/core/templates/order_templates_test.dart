import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/application/models/scoring/entered_line_definition.dart';
import 'package:scoard_game/application/models/scoring/score_input_kind.dart';
import 'package:scoard_game/application/models/scoring/scoring_model.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/application/models/scoring/winner_rule.dart';
import 'package:scoard_game/core/templates/order_templates.dart';

ScoringPreset template(String name, {bool general = false}) {
  return ScoringPreset(
    id: name.toLowerCase(),
    displayName: name,
    description: 'x',
    isGeneral: general,
    scoringModel: ScoringModel.rounds,
    minimumPlayers: 2,
    winnerRule: WinnerRule.highestScoreWins,
    enteredLines: const [
      EnteredLineDefinition(
        id: 'score',
        label: 'Score',
        inputKind: ScoreInputKind.integer,
        isEntered: true,
        contributesToFinalResult: true,
      ),
    ],
  );
}

void main() {
  test('general templates first, then games by last played, then by name', () {
    final choices = orderTemplatesForPicker(
      [
        template('Skyjo'),
        template('Round Score', general: true),
        template('Azul'),
        template('Cornhole'),
        template('Quick Score', general: true),
        template('Wingspan'),
      ],
      {
        'cornhole': DateTime(2026, 10, 1),
        'skyjo': DateTime(2026, 10, 9),
        // A general template's use does not move it.
        'round score': DateTime(2026, 10, 10),
      },
    );

    expect(
      choices.general.map((t) => t.displayName),
      ['Quick Score', 'Round Score'],
    );
    expect(
      choices.games.map((t) => t.displayName),
      ['Skyjo', 'Cornhole', 'Azul', 'Wingspan'],
    );
  });
}
