import 'package:scoard_game/application/models/scoring/calculated_field_definition.dart';
import 'package:scoard_game/application/models/scoring/marker_field_definition.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_behavior.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_definition.dart';
import 'package:scoard_game/application/models/scoring/score_field_definition.dart';
import 'package:scoard_game/application/models/scoring/score_input_kind.dart';
import 'package:scoard_game/application/models/scoring/scoring_model.dart';
import 'package:scoard_game/application/models/scoring/score_row_label.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/application/models/scoring/value_picker_definition.dart';
import 'package:scoard_game/application/models/scoring/winner_rule.dart';

/// Builds a [ScoringPreset] from a template that has already passed
/// `validateTemplateJson`.
///
/// Version 1's `scoreField` and version 2's `fields` and `score` produce the
/// same model: entered fields, calculated fields, and which one is the score.
ScoringPreset parseTemplateJson(Map<String, Object?> json) {
  final players = json['players']! as Map<String, Object?>;
  final prompts = (json['prompts'] as List<Object?>?) ?? const [];
  final fields = [
    if (json['fields'] case final List<Object?> fields)
      for (final field in fields) field! as Map<String, Object?>
    else
      json['scoreField']! as Map<String, Object?>,
  ];
  final markerFields =
      fields.where((field) => field.containsKey('marker')).toList();
  final calculatedFields =
      fields.where((field) => field.containsKey('formula')).toList();
  final enteredFields = fields
      .where(
        (field) => !field.containsKey('formula') && !field.containsKey('marker'),
      )
      .toList();

  return ScoringPreset(
    id: json['id']! as String,
    version: json['version']! as String,
    displayName: json['name']! as String,
    subtitle: json['subtitle'] as String?,
    isGeneral: (json['general'] as bool?) ?? false,
    description: json['description']! as String,
    source: json['source'] as String?,
    scoringModel: switch (json['scoringModel']) {
      'rounds' => ScoringModel.rounds,
      _ => ScoringModel.finalScore,
    },
    minimumPlayers: players['minimum']! as int,
    maximumPlayers: players['maximum'] as int?,
    winnerRule: switch (json['winner']) {
      'lowestScore' => WinnerRule.lowestScoreWins,
      _ => WinnerRule.highestScoreWins,
    },
    promptDefinitions: prompts
        .map((prompt) => _parsePrompt(prompt! as Map<String, Object?>))
        .toList(growable: false),
    scoreFields: enteredFields.map(_parseEnteredField).toList(growable: false),
    calculatedFields: [
      for (final field in calculatedFields)
        CalculatedFieldDefinition(
          id: field['id']! as String,
          label: field['label']! as String,
          formula: field['formula']! as String,
        ),
    ],
    markerFields: [
      for (final field in markerFields)
        if (field['marker'] case final Map<String, Object?> marker)
          MarkerFieldDefinition(
            id: field['id']! as String,
            label: field['label']! as String,
            badge: marker['badge']! as String,
            color: marker['color'] as String?,
            onePerRound: (marker['onePerRound'] as bool?) ?? false,
          ),
    ],
    scoreFieldId: json['score'] as String?,
  );
}

ScoreFieldDefinition _parseEnteredField(Map<String, Object?> field) {
  final entry = (field['entry'] as Map<String, Object?>?) ?? const {};

  return ScoreFieldDefinition(
    id: field['id']! as String,
    label: field['label']! as String,
    inputKind: ScoreInputKind.integer,
    isEntered: true,
    contributesToFinalResult: true,
    initialIntegerValue: field['initialValue'] as int?,
    minimumDisplayDigits: (field['minimumDisplayDigits'] as int?) ?? 1,
    enableTapToEdit: (entry['tapToEdit'] as bool?) ?? false,
    enableQuickAdjust: (entry['quickAdjust'] as bool?) ?? false,
    allowReplace: (entry['replace'] as bool?) ?? true,
    allowAdjust: (entry['adjust'] as bool?) ?? false,
    valuePickers: ((field['entryModes'] as List<Object?>?) ?? const [])
        .map((mode) => _parseValuePicker(mode! as Map<String, Object?>))
        .toList(growable: false),
  );
}

ValuePickerDefinition _parseValuePicker(Map<String, Object?> mode) {
  ValuePickerOption parseTile(Object? rawTile, String? groupId) {
    final tile = rawTile! as Map<String, Object?>;
    return ValuePickerOption(
      value: tile['value']! as int,
      label: tile['label'] as String?,
      color: tile['color'] as String?,
      text: tile['text'] as String?,
      groupId: groupId,
    );
  }

  final options = <ValuePickerOption>[];
  if (mode['groups'] case final List<Object?> groups) {
    for (final rawGroup in groups) {
      final group = rawGroup! as Map<String, Object?>;
      final groupId = group['id']! as String;
      for (final tile in group['values']! as List<Object?>) {
        options.add(parseTile(tile, groupId));
      }
    }
  } else {
    for (final tile in mode['values']! as List<Object?>) {
      options.add(parseTile(tile, null));
    }
  }

  return ValuePickerDefinition(
    id: mode['id']! as String,
    label: mode['label']! as String,
    options: options,
    total: mode['total'] as String?,
    rowLabels: [
      for (final rawLabel in (mode['rowLabels'] as List<Object?>?) ?? const [])
        if (rawLabel case final Map<String, Object?> label)
          ValuePickerRowLabel(
            when: label['when']! as String,
            text: label['text']! as String,
            color: label['color'] as String?,
            isBadge: label['show'] == 'badge',
            size: RowLabelSize.values.asNameMap()[label['size']] ??
                RowLabelSize.large,
          ),
    ],
  );
}

PresetPromptDefinition _parsePrompt(Map<String, Object?> prompt) {
  final id = prompt['id']! as String;
  final label = prompt['label']! as String;
  final help = prompt['help'] as String?;
  final behavior = switch (prompt['effect']) {
    'lowScoreWins' => PresetPromptBehavior.winnerRuleLowScoreToggle,
    _ => null,
  };

  return switch (prompt['type']) {
    'integer' => PresetPromptDefinition.integer(
        id: id,
        label: label,
        promptText: help,
        behavior: behavior,
        defaultIntegerValue: prompt['default'] as int?,
      ),
    _ => PresetPromptDefinition.boolean(
        id: id,
        label: label,
        promptText: help,
        behavior: behavior,
        defaultBooleanValue: (prompt['default'] as bool?) ?? false,
      ),
  };
}
