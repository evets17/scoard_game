import 'package:scoard_game/application/models/scoring/scoring_preset.dart';

/// Chooses between the bundled templates and the online ones.
///
/// An online template replaces the bundled one with the same id unless the
/// bundled `version` is higher, so an online fix lands without a version
/// bump while a newer app release still wins. Online templates with no
/// bundled match are added.
List<ScoringPreset> mergeTemplateSources({
  required List<ScoringPreset> bundled,
  required List<ScoringPreset> online,
}) {
  final byId = {for (final template in bundled) template.id: template};
  for (final template in online) {
    final existing = byId[template.id];
    if (existing == null ||
        compareTemplateVersions(existing.version, template.version) <= 0) {
      byId[template.id] = template;
    }
  }
  return byId.values.toList(growable: false);
}

/// Compares versions like `2.10.0` part by part, as numbers. Negative when
/// [left] is lower.
int compareTemplateVersions(String left, String right) {
  List<int> parts(String version) =>
      version.split('.').map((part) => int.tryParse(part) ?? 0).toList();

  final leftParts = parts(left);
  final rightParts = parts(right);
  final length = leftParts.length > rightParts.length
      ? leftParts.length
      : rightParts.length;
  for (var index = 0; index < length; index++) {
    final leftPart = index < leftParts.length ? leftParts[index] : 0;
    final rightPart = index < rightParts.length ? rightParts[index] : 0;
    if (leftPart != rightPart) {
      return leftPart.compareTo(rightPart);
    }
  }
  return 0;
}
