import 'package:scoard_game/application/models/scoring/scoring_preset.dart';

/// Templates as Score a Game lists them.
typedef ScoreGameChoices = ({
  List<ScoringPreset> general,
  List<ScoringPreset> games,
});

/// General scoring styles first, by name. Then games, most recently played
/// first, followed by games not played yet, by name.
ScoreGameChoices orderTemplatesForPicker(
  List<ScoringPreset> templates,
  Map<String, DateTime> lastPlayedAtByTemplateId,
) {
  int byName(ScoringPreset left, ScoringPreset right) => left.displayName
      .toLowerCase()
      .compareTo(right.displayName.toLowerCase());

  final general = templates.where((template) => template.isGeneral).toList()
    ..sort(byName);

  final games = templates.where((template) => !template.isGeneral).toList()
    ..sort((left, right) {
      final leftPlayed = lastPlayedAtByTemplateId[left.id];
      final rightPlayed = lastPlayedAtByTemplateId[right.id];
      if (leftPlayed != null && rightPlayed != null) {
        final comparison = rightPlayed.compareTo(leftPlayed);
        if (comparison != 0) {
          return comparison;
        }
      } else if (leftPlayed != null) {
        return -1;
      } else if (rightPlayed != null) {
        return 1;
      }
      return byName(left, right);
    });

  return (general: general, games: games);
}
