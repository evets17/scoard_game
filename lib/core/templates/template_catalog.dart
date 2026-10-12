import 'dart:convert';

import 'package:scoard_game/application/models/scoring/scoring_model.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/core/templates/template_parser.dart';
import 'package:scoard_game/core/templates/template_validator.dart';

/// Every available scoring template, looked up synchronously after startup.
class TemplateCatalog {
  TemplateCatalog(List<ScoringPreset> templates)
      : templates = List.unmodifiable(
          [...templates]..sort(
              (left, right) => left.displayName
                  .toLowerCase()
                  .compareTo(right.displayName.toLowerCase()),
            ),
        );

  /// Sorted by name, as listed in Score a Game.
  final List<ScoringPreset> templates;

  ScoringPreset? maybeById(String id) {
    for (final template in templates) {
      if (template.id == id) {
        return template;
      }
    }
    return null;
  }

  ScoringPreset byId(String id) {
    final template = maybeById(id);
    if (template == null) {
      throw StateError('No scoring template with id "$id".');
    }
    return template;
  }

  /// The first template using [scoringModel], for when none was chosen.
  ScoringPreset firstFor(ScoringModel scoringModel) {
    return templates.firstWhere(
      (template) => template.scoringModel == scoringModel,
    );
  }
}

class TemplateCatalogLoadResult {
  const TemplateCatalogLoadResult({
    required this.catalog,
    required this.problemsByFile,
  });

  final TemplateCatalog catalog;

  /// Problems per template file. Files with problems are left out of the
  /// catalog.
  final Map<String, List<TemplateProblem>> problemsByFile;

  bool get hasProblems => problemsByFile.isNotEmpty;

  String describeProblems() {
    return [
      for (final entry in problemsByFile.entries)
        for (final problem in entry.value) '${entry.key}: $problem',
    ].join('\n');
  }
}

/// Validates and parses template files, keyed by file path.
///
/// The template id each file must declare is its file name without `.json`.
TemplateCatalogLoadResult loadTemplateCatalog(Map<String, String> filesByPath) {
  final templates = <ScoringPreset>[];
  final problemsByFile = <String, List<TemplateProblem>>{};
  final pathsById = <String, String>{};

  final sortedPaths = filesByPath.keys.toList()..sort();
  for (final path in sortedPaths) {
    final expectedId = templateIdFromPath(path);
    final Object? json;
    try {
      json = jsonDecode(filesByPath[path]!);
    } on FormatException catch (error) {
      problemsByFile[path] = [
        TemplateProblem('', 'is not valid JSON: ${error.message}'),
      ];
      continue;
    }

    final problems = validateTemplateJson(json, expectedId: expectedId);
    if (problems.isEmpty) {
      final existingPath = pathsById[expectedId];
      if (existingPath != null) {
        problems.add(
          TemplateProblem('id', '"$expectedId" is already used by $existingPath'),
        );
      }
    }

    if (problems.isNotEmpty) {
      problemsByFile[path] = problems;
      continue;
    }

    pathsById[expectedId] = path;
    templates.add(parseTemplateJson(json! as Map<String, Object?>));
  }

  return TemplateCatalogLoadResult(
    catalog: TemplateCatalog(templates),
    problemsByFile: problemsByFile,
  );
}

String templateIdFromPath(String path) {
  final fileName = path.split(RegExp(r'[/\\]')).last;
  return fileName.endsWith('.json')
      ? fileName.substring(0, fileName.length - '.json'.length)
      : fileName;
}
