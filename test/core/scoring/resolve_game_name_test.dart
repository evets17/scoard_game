import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_answer.dart';
import 'package:scoard_game/core/scoring/resolve_preset_options.dart';

import '../../support/test_templates.dart';

void main() {
  final catalog = loadTestTemplateCatalog();

  test('the game name is the answer, else the default, else the name', () {
    final quickScore = catalog.byId('quick-final-score-basic');
    String nameFor(List<PresetPromptAnswer> answers) =>
        resolvePresetOptions(preset: quickScore, promptAnswers: answers)
            .gameName;

    expect(
      nameFor(const [PresetPromptAnswer.text(id: 'game-name', value: 'Catan')]),
      'Catan',
    );
    expect(
      nameFor(const [PresetPromptAnswer.text(id: 'game-name', value: '  ')]),
      'Quick Score',
    );
    expect(nameFor(const []), 'Quick Score');
    // A text answer is not a number formulas read.
    expect(
      resolvePresetOptions(preset: quickScore).formulaValues.keys,
      isNot(contains('game-name')),
    );

    expect(
      resolvePresetOptions(preset: catalog.byId('skyjo')).gameName,
      'Skyjo',
    );
  });

  test('a text answer survives saving', () {
    const answer = PresetPromptAnswer.text(id: 'game-name', value: 'Catan');
    final restored = PresetPromptAnswer.fromJson(answer.toJson());
    expect(restored.textValue, 'Catan');
    expect(restored.id, 'game-name');
  });
}
