import 'package:scoard_game/application/models/scoring/card_text.dart';
import 'package:scoard_game/application/models/scoring/card_text_definition.dart';
import 'package:scoard_game/application/models/scoring/calculated_line_definition.dart';
import 'package:scoard_game/application/models/scoring/marker_line_definition.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_behavior.dart';
import 'package:scoard_game/application/models/scoring/preset_prompt_definition.dart';
import 'package:scoard_game/application/models/scoring/entered_line_definition.dart';
import 'package:scoard_game/application/models/scoring/score_input_kind.dart';
import 'package:scoard_game/application/models/scoring/scoring_model.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/application/models/scoring/sheet_layout.dart';
import 'package:scoard_game/application/models/scoring/template_origin.dart';
import 'package:scoard_game/application/models/scoring/value_picker_definition.dart';
import 'package:scoard_game/application/models/scoring/winner_rule.dart';

/// Builds a [ScoringPreset] from a template that has already passed
/// `validateTemplateJson`.
///
/// The score sheet's `lines` become entered, calculated, and marker lines,
/// and `score` says which line is the score.
ScoringPreset parseTemplateJson(
  Map<String, Object?> json, {
  TemplateOrigin origin = TemplateOrigin.bundled,
}) {
  final players = json['players']! as Map<String, Object?>;
  final prompts = (json['prompts'] as List<Object?>?) ?? const [];
  final items = [
    for (final item in json['lines']! as List<Object?>)
      item! as Map<String, Object?>,
  ];
  // Headings only lay out the sheet; the rest are lines.
  final lines = items.where((item) => !item.containsKey('heading')).toList();
  final markerLines =
      lines.where((line) => line.containsKey('marker')).toList();
  final calculatedLines =
      lines.where((line) => line.containsKey('formula')).toList();
  final enteredLines = lines
      .where(
        (line) => !line.containsKey('formula') && !line.containsKey('marker'),
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
    enteredLines: enteredLines.map(_parseEnteredLine).toList(growable: false),
    calculatedLines: [
      for (final line in calculatedLines)
        CalculatedLineDefinition(
          id: line['id']! as String,
          label: line['label']! as String,
          formula: line['formula']! as String,
        ),
    ],
    markerLines: [
      for (final line in markerLines)
        if (line['marker'] case final Map<String, Object?> marker)
          MarkerLineDefinition(
            id: line['id']! as String,
            label: line['label']! as String,
            badge: marker['badge']! as String,
            color: marker['color'] as String?,
            onePerRound: (marker['onePerRound'] as bool?) ?? false,
          ),
    ],
    scoreLineId: json['score'] as String?,
    sheetLayout: [
      for (final item in items)
        if (item['heading'] case final String heading)
          SheetLayoutItem.heading(heading, style: _parseRowStyle(item['style']))
        else
          SheetLayoutItem.line(
            item['id']! as String,
            style: _parseRowStyle(item['style']),
            image: item['image'] as String?,
          ),
    ],
    lineLabels: _parseLabelDisplay(json['lineLabels']) ?? LineLabelDisplay.text,
    declaredEntryOrder: switch (json['entryOrder']) {
      'byPlayer' => SheetEntryOrder.byPlayer,
      'byLine' => SheetEntryOrder.byLine,
      _ => null,
    },
    scoreLabels: _parseCardTexts(json['scoreLabels']),
    scoreSubLabels: _parseCardTexts(json['scoreSubLabels']),
    playerBadges: _parseCardTexts(json['playerBadges']),
    origin: origin,
  );
}

EnteredLineDefinition _parseEnteredLine(Map<String, Object?> line) {
  final entry = (line['entry'] as Map<String, Object?>?) ?? const {};
  final quickPick = entry['quickPick'] as Map<String, Object?>?;

  return EnteredLineDefinition(
    id: line['id']! as String,
    label: line['label']! as String,
    inputKind: ScoreInputKind.integer,
    isEntered: true,
    contributesToFinalResult: true,
    initialIntegerValue: line['initialValue'] as int?,
    minimumDisplayDigits: (line['minimumDisplayDigits'] as int?) ?? 1,
    enableTapToEdit: (entry['tapToEdit'] as bool?) ?? false,
    enableQuickAdjust: (entry['quickAdjust'] as bool?) ?? false,
    allowReplace: (entry['replace'] as bool?) ?? true,
    allowAdjust: (entry['adjust'] as bool?) ?? false,
    valuePickers: ((line['entryModes'] as List<Object?>?) ?? const [])
        .map((mode) => _parseValuePicker(mode! as Map<String, Object?>))
        .toList(growable: false),
    quickPickRange: quickPick == null
        ? null
        : (quickPick['min']! as int, quickPick['max']! as int),
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

List<CardTextDefinition> _parseCardTexts(Object? rawList) {
  return [
    for (final raw in (rawList as List<Object?>?) ?? const [])
      if (raw case final Map<String, Object?> cardText)
        CardTextDefinition(
          when: cardText['when']! as String,
          text: cardText['text']! as String,
          color: cardText['color'] as String?,
          size: CardTextSize.values.asNameMap()[cardText['size']] ??
              CardTextSize.large,
        ),
  ];
}

SheetRowStyle _parseRowStyle(Object? raw) {
  if (raw is! Map<String, Object?>) {
    return SheetRowStyle.plain;
  }
  return SheetRowStyle(
    shade: raw['shade'] as String?,
    bold: (raw['bold'] as bool?) ?? false,
    ruleAbove: (raw['ruleAbove'] as bool?) ?? false,
    label: _parseLabelDisplay(raw['label']),
  );
}

LineLabelDisplay? _parseLabelDisplay(Object? raw) =>
    raw is String ? LineLabelDisplay.values.asNameMap()[raw] : null;
