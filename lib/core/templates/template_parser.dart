import 'package:scoard_game/application/models/scoring/preset_prompt_behavior.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_definition.dart';
import 'package:scoard_game/application/models/scoring/score_field_definition.dart';
import 'package:scoard_game/application/models/scoring/score_input_kind.dart';
import 'package:scoard_game/application/models/scoring/scoring_model.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/application/models/scoring/value_picker_definition.dart';
import 'package:scoard_game/application/models/scoring/winner_rule.dart';

/// Builds a [ScoringPreset] from a template that has already passed
/// `validateTemplateJson`.
ScoringPreset parseTemplateJson(Map<String, Object?> json) {
  final players = json['players']! as Map<String, Object?>;
  final scoreField = json['scoreField']! as Map<String, Object?>;
  final entry = (scoreField['entry'] as Map<String, Object?>?) ?? const {};
  final prompts = (json['prompts'] as List<Object?>?) ?? const [];

  return ScoringPreset(
    id: json['id']! as String,
    version: json['version']! as String,
    displayName: json['name']! as String,
    subtitle: json['subtitle'] as String?,
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
    scoreFields: [
      ScoreFieldDefinition(
        id: scoreField['id']! as String,
        label: scoreField['label']! as String,
        inputKind: ScoreInputKind.integer,
        isEntered: true,
        contributesToFinalResult: true,
        initialIntegerValue: scoreField['initialValue'] as int?,
        minimumDisplayDigits: (scoreField['minimumDisplayDigits'] as int?) ?? 1,
        enableTapToEdit: (entry['tapToEdit'] as bool?) ?? false,
        enableQuickAdjust: (entry['quickAdjust'] as bool?) ?? false,
        allowReplace: (entry['replace'] as bool?) ?? true,
        allowAdjust: (entry['adjust'] as bool?) ?? false,
        valuePickers: ((scoreField['entryModes'] as List<Object?>?) ?? const [])
            .map((mode) => _parseValuePicker(mode! as Map<String, Object?>))
            .toList(growable: false),
      ),
    ],
  );
}

ValuePickerDefinition _parseValuePicker(Map<String, Object?> mode) {
  final values = mode['values']! as List<Object?>;

  return ValuePickerDefinition(
    id: mode['id']! as String,
    label: mode['label']! as String,
    options: values.map((rawOption) {
      final option = rawOption! as Map<String, Object?>;
      return ValuePickerOption(
        value: option['value']! as int,
        label: option['label'] as String?,
        color: option['color'] as String?,
      );
    }).toList(growable: false),
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
