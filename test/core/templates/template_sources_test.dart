import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/application/models/scoring/entered_line_definition.dart';
import 'package:scoard_game/application/models/scoring/score_input_kind.dart';
import 'package:scoard_game/application/models/scoring/scoring_model.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/application/models/scoring/template_origin.dart';
import 'package:scoard_game/application/models/scoring/winner_rule.dart';
import 'package:scoard_game/core/templates/template_sources.dart';

ScoringPreset template(
  String id,
  String version, {
  TemplateOrigin origin = TemplateOrigin.bundled,
}) {
  return ScoringPreset(
    id: id,
    displayName: id,
    description: 'x',
    scoringModel: ScoringModel.rounds,
    minimumPlayers: 2,
    winnerRule: WinnerRule.highestScoreWins,
    enteredLines: const [
      EnteredLineDefinition(
        id: 'points',
        label: 'Points',
        inputKind: ScoreInputKind.integer,
        isEntered: true,
        contributesToFinalResult: true,
      ),
    ],
    version: version,
    origin: origin,
  );
}

void main() {
  Map<String, String> chosen(List<ScoringPreset> templates) => {
        for (final template in templates)
          template.id: '${template.version} ${template.origin.name}',
      };

  test('online replaces bundled unless bundled is newer', () {
    final merged = mergeTemplateSources(
      bundled: [
        template('same', '1.0.0'),
        template('newer-online', '1.0.0'),
        template('newer-bundled', '2.0.0'),
        template('bundled-only', '1.0.0'),
      ],
      online: [
        template('same', '1.0.0', origin: TemplateOrigin.online),
        template('newer-online', '1.1.0', origin: TemplateOrigin.online),
        template('newer-bundled', '1.9.0', origin: TemplateOrigin.online),
        template('online-only', '1.0.0', origin: TemplateOrigin.online),
      ],
    );

    expect(chosen(merged), {
      'same': '1.0.0 online',
      'newer-online': '1.1.0 online',
      'newer-bundled': '2.0.0 bundled',
      'bundled-only': '1.0.0 bundled',
      'online-only': '1.0.0 online',
    });
  });

  test('versions compare as numbers, part by part', () {
    expect(compareTemplateVersions('2.10.0', '2.9.0'), greaterThan(0));
    expect(compareTemplateVersions('1.0.0', '1.0.1'), lessThan(0));
    expect(compareTemplateVersions('3.0.0', '3.0.0'), 0);
    expect(compareTemplateVersions('1.0', '1.0.0'), 0);
  });
}
