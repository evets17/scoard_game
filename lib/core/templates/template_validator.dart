/// Checks a decoded template file against the template schema.
///
/// See `_specs/template_schema_v1.md` and `template_schema_v2.md`. Every
/// problem is reported, not just the first, so a template can be fixed in
/// one pass.
library;

import 'package:scoard_game/core/formulas/formula_checker.dart';
import 'package:scoard_game/core/formulas/formula_parser.dart';
import 'package:scoard_game/core/scoring/score_engine.dart';

const supportedTemplateSchemaVersions = {1, 2};

const templateScoringModels = {'finalScore', 'rounds'};
const templateWinnerRules = {'highestScore', 'lowestScore'};
const templatePromptTypes = {'boolean', 'integer'};

/// Prompt effects and the prompt type each one needs.
const templatePromptEffects = {'lowScoreWins': 'boolean'};

/// Template-defined score entry modes.
const templateEntryModeTypes = {'valuePicker'};

/// Keeps a value picker small enough to fit on a phone without scrolling.
const maximumPickerValues = 24;

/// Keeps tile text readable on a small tile, for example "+10" or "Bust".
const maximumTileTextLength = 6;

/// Keeps a row label inside the space a score normally takes.
const maximumRowLabelLength = 8;

final _idPattern = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');
final _colorPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');
final _versionPattern = RegExp(r'^\d+\.\d+\.\d+$');

class TemplateProblem {
  const TemplateProblem(this.path, this.message);

  /// Where the problem is, for example `prompts[0].effect`. Empty for the
  /// file as a whole.
  final String path;
  final String message;

  @override
  String toString() => path.isEmpty ? message : '$path: $message';
}

/// Validates one template. [expectedId] is the id implied by the file name.
List<TemplateProblem> validateTemplateJson(
  Object? json, {
  String? expectedId,
}) {
  final problems = <TemplateProblem>[];
  final template = _ObjectReader(json, '', problems);
  if (!template.isObject) {
    return problems;
  }

  final schemaVersion = template.integer('schemaVersion', required: true);
  if (schemaVersion != null &&
      !supportedTemplateSchemaVersions.contains(schemaVersion)) {
    template.problem(
      'schemaVersion',
      'unsupported version $schemaVersion; expected one of: '
          '${supportedTemplateSchemaVersions.join(', ')}',
    );
  }
  final isVersion2 = schemaVersion == 2;

  template.allowOnlyKeys({
    'schemaVersion',
    'id',
    'version',
    'name',
    'subtitle',
    'general',
    'description',
    'source',
    'players',
    'scoringModel',
    'winner',
    'prompts',
    if (isVersion2) ...{'fields', 'score'} else 'scoreField',
  });

  final id = template.identifier('id', required: true);
  if (id != null && expectedId != null && id != expectedId) {
    template.problem('id', '"$id" does not match the file name "$expectedId"');
  }

  final version = template.text('version', required: true);
  if (version != null && !_versionPattern.hasMatch(version)) {
    template.problem('version', '"$version" must look like 1.0.0');
  }

  template.text('name', required: true);
  template.text('subtitle');
  template.boolean('general');
  template.text('description', required: true);
  template.text('source');
  template.oneOf('scoringModel', templateScoringModels, required: true);
  template.oneOf('winner', templateWinnerRules, required: true);

  final players = template.object('players', required: true);
  if (players != null) {
    players.allowOnlyKeys(const {'minimum', 'maximum'});
    final minimum = players.integer('minimum', required: true);
    final maximum = players.integer('maximum');
    if (minimum != null && minimum < 1) {
      players.problem('minimum', 'must be at least 1');
    }
    if (minimum != null && maximum != null && maximum < minimum) {
      players.problem('maximum', 'must not be less than minimum ($minimum)');
    }
  }

  final prompts = template.list('prompts');
  final seenPromptIds = <String>{};
  if (prompts != null) {
    for (final prompt in prompts) {
      if (!prompt.isObject) {
        continue;
      }
      _validatePrompt(prompt, seenPromptIds);
    }
  }

  if (isVersion2) {
    _validateFields(template, seenPromptIds);
  } else {
    final scoreField = template.object('scoreField', required: true);
    if (scoreField != null) {
      _validateEnteredField(scoreField);
    }
  }

  return problems;
}

/// A field whose value players enter. Returns its id if it is valid.
String? _validateEnteredField(_ObjectReader field) {
  field.allowOnlyKeys(const {
    'id',
    'label',
    'initialValue',
    'minimumDisplayDigits',
    'entry',
    'entryModes',
  });
  final id = field.identifier('id', required: true);
  field.text('label', required: true);
  field.integer('initialValue');
  final digits = field.integer('minimumDisplayDigits');
  if (digits != null && digits < 1) {
    field.problem('minimumDisplayDigits', 'must be at least 1');
  }

  var tapToEdit = false;
  final entry = field.object('entry');
  if (entry != null) {
    const entryKeys = {'tapToEdit', 'quickAdjust', 'replace', 'adjust'};
    entry.allowOnlyKeys(entryKeys);
    for (final key in entryKeys) {
      final value = entry.boolean(key);
      if (key == 'tapToEdit') {
        tapToEdit = value ?? false;
      }
    }
  }

  final entryModes = field.list('entryModes');
  if (entryModes != null && entryModes.isNotEmpty && !tapToEdit) {
    field.problem(
      'entryModes',
      'need entry.tapToEdit to be true, or the entry sheet never opens',
    );
  }
  if (entryModes != null) {
    final seenModeIds = <String>{};
    for (final mode in entryModes) {
      if (mode.isObject) {
        _validateEntryMode(mode, seenModeIds);
      }
    }
  }

  return id;
}

/// A flag players set by hand each round. Returns its id if it is valid.
String? _validateMarkerField(_ObjectReader field) {
  field.allowOnlyKeys(const {'id', 'label', 'marker'});
  final id = field.identifier('id', required: true);
  field.text('label', required: true);

  final marker = field.object('marker', required: true);
  if (marker != null) {
    marker.allowOnlyKeys(const {'badge', 'color', 'onePerRound'});
    final badge = marker.text('badge', required: true);
    if (badge != null && badge.length > maximumRowLabelLength) {
      marker.problem('badge', 'must be at most $maximumRowLabelLength characters');
    }
    final color = marker.text('color');
    if (color != null && !_colorPattern.hasMatch(color)) {
      marker.problem('color', '"$color" must look like #3A7BD5');
    }
    marker.boolean('onePerRound');
  }

  return id;
}

/// Version 2: `fields` (entered, calculated, and marker) and `score`.
/// [promptIds] can be read by formulas, so fields may not reuse them.
void _validateFields(_ObjectReader template, Set<String> promptIds) {
  final fields = template.list('fields', required: true);
  final scoreId = template.identifier('score', required: true);
  if (fields == null) {
    return;
  }

  final fieldIds = <String>{};
  final calculated = <({_ObjectReader reader, String id, Formula formula})>[];
  var enteredCount = 0;

  void addId(_ObjectReader field, String? id) {
    if (id != null && !fieldIds.add(id)) {
      field.problem('id', 'duplicate field id "$id"');
    }
    if (id != null && (promptIds.contains(id) || formulaBuiltIns.contains(id))) {
      field.problem('id', '"$id" is already the name of a prompt or built-in value');
    }
  }

  for (final field in fields) {
    if (!field.isObject) {
      continue;
    }

    if (field.has('marker')) {
      addId(field, _validateMarkerField(field));
      continue;
    }

    if (!field.has('formula')) {
      enteredCount += 1;
      addId(field, _validateEnteredField(field));
      continue;
    }

    field.allowOnlyKeys(const {'id', 'label', 'formula'});
    final id = field.identifier('id', required: true);
    field.text('label', required: true);
    final source = field.text('formula', required: true);
    addId(field, id);
    if (id == null || source == null) {
      continue;
    }
    try {
      calculated.add((reader: field, id: id, formula: Formula.parse(source)));
    } on FormulaSyntaxError catch (error) {
      field.problem('formula', error.toString());
    }
  }

  if (enteredCount != 1) {
    template.problem(
      'fields',
      'needs exactly one entered field (a field without a formula); '
          'found $enteredCount',
    );
  }

  // Names and functions first; loops only make sense once names are right.
  final dependencies = <String, Set<String>>{};
  var formulasAreSound = true;
  for (final field in calculated) {
    final reads = <String>{};
    final problems = checkFormula(
      field.formula,
      fieldIds: fieldIds,
      promptIds: promptIds,
      dependencies: reads,
    );
    for (final problem in problems) {
      field.reader.problem('formula', problem.toString());
    }
    formulasAreSound = formulasAreSound && problems.isEmpty;
    dependencies[field.id] = reads;
  }

  if (formulasAreSound) {
    try {
      orderCalculatedFields(dependencies);
    } on CircularFormulaError catch (error) {
      final start = calculated.firstWhere((field) => field.id == error.loop.first);
      start.reader.problem('formula', error.toString());
    }
  }

  if (scoreId != null && fieldIds.isNotEmpty && !fieldIds.contains(scoreId)) {
    template.problem(
      'score',
      '"$scoreId" is not one of the fields: ${fieldIds.join(', ')}',
    );
  }
}

void _validateEntryMode(_ObjectReader mode, Set<String> seenModeIds) {
  mode.allowOnlyKeys(
    const {'type', 'id', 'label', 'values', 'groups', 'total', 'rowLabels'},
  );
  mode.oneOf('type', templateEntryModeTypes, required: true);

  final id = mode.identifier('id', required: true);
  if (id != null && !seenModeIds.add(id)) {
    mode.problem('id', 'duplicate entry mode id "$id"');
  }
  mode.text('label', required: true);

  final hasValues = mode.has('values');
  final hasGroups = mode.has('groups');
  if (hasValues == hasGroups) {
    mode.problem(
      hasValues ? 'groups' : 'values',
      'use either "values" or "groups", not ${hasValues ? 'both' : 'neither'}',
    );
    return;
  }

  // Tiles are told apart by what they show, so "2" and "+2" can both exist.
  final seenTiles = <String>{};
  var tileCount = 0;

  void validateTiles(List<_ObjectReader> tiles) {
    for (final tile in tiles) {
      if (!tile.isObject) {
        continue;
      }
      tileCount += 1;
      tile.allowOnlyKeys(const {'value', 'label', 'color', 'text'});
      final value = tile.integer('value', required: true);
      final text = tile.text('text');
      if (text != null && text.length > maximumTileTextLength) {
        tile.problem('text', 'must be at most $maximumTileTextLength characters');
      }
      final shown = text ?? (value == null ? null : '$value');
      if (shown != null && !seenTiles.add(shown)) {
        tile.problem(text == null ? 'value' : 'text', 'duplicate tile "$shown"');
      }
      tile.text('label');
      final color = tile.text('color');
      if (color != null && !_colorPattern.hasMatch(color)) {
        tile.problem('color', '"$color" must look like #3A7BD5');
      }
    }
  }

  final groupIds = <String>{};
  if (hasValues) {
    final values = mode.list('values', required: true);
    if (values != null) {
      if (values.isEmpty) {
        mode.problem('values', 'needs at least one value');
      }
      validateTiles(values);
    }
    if (mode.has('total')) {
      mode.problem('total', 'needs "groups"; without groups the tiles are added up');
    }
    if (mode.has('rowLabels')) {
      mode.problem('rowLabels', 'needs "groups" so a label can say which tiles it is about');
    }
  } else {
    final groups = mode.list('groups', required: true) ?? const [];
    if (groups.isEmpty) {
      mode.problem('groups', 'needs at least one group');
    }
    for (final group in groups) {
      if (!group.isObject) {
        continue;
      }
      group.allowOnlyKeys(const {'id', 'values'});
      final groupId = group.identifier('id', required: true);
      if (groupId != null && !groupIds.add(groupId)) {
        group.problem('id', 'duplicate group id "$groupId"');
      }
      final values = group.list('values', required: true);
      if (values != null) {
        if (values.isEmpty) {
          group.problem('values', 'needs at least one value');
        }
        validateTiles(values);
      }
    }

    final total = mode.text('total');
    if (total != null) {
      try {
        final problems = checkFormula(
          Formula.parse(total),
          fieldIds: groupIds,
          context: FormulaContext.picker,
        );
        for (final problem in problems) {
          mode.problem('total', problem.toString());
        }
      } on FormulaSyntaxError catch (error) {
        mode.problem('total', error.toString());
      }
    }

    for (final rowLabel in mode.list('rowLabels') ?? const <_ObjectReader>[]) {
      if (!rowLabel.isObject) {
        continue;
      }
      rowLabel.allowOnlyKeys(const {'when', 'text', 'color', 'show', 'size'});
      final show = rowLabel.oneOf('show', const {'replace', 'badge'});
      final size =
          rowLabel.oneOf('size', const {'small', 'medium', 'large'});
      if (show == 'badge' && size != null) {
        rowLabel.problem('size', 'only applies to labels shown instead of the score');
      }
      final text = rowLabel.text('text', required: true);
      if (text != null && text.length > maximumRowLabelLength) {
        rowLabel.problem(
          'text',
          'must be at most $maximumRowLabelLength characters',
        );
      }
      final color = rowLabel.text('color');
      if (color != null && !_colorPattern.hasMatch(color)) {
        rowLabel.problem('color', '"$color" must look like #3A7BD5');
      }
      final when = rowLabel.text('when', required: true);
      if (when == null) {
        continue;
      }
      try {
        final problems = checkFormula(
          Formula.parse(when),
          fieldIds: groupIds,
          context: FormulaContext.picker,
        );
        for (final problem in problems) {
          rowLabel.problem('when', problem.toString());
        }
      } on FormulaSyntaxError catch (error) {
        rowLabel.problem('when', error.toString());
      }
    }
  }

  if (tileCount > maximumPickerValues) {
    mode.problem(
      hasValues ? 'values' : 'groups',
      'has $tileCount tiles; the most is $maximumPickerValues',
    );
  }
}

void _validatePrompt(_ObjectReader prompt, Set<String> seenPromptIds) {
  prompt.allowOnlyKeys(const {'id', 'type', 'label', 'help', 'default', 'effect'});

  final id = prompt.identifier('id', required: true);
  if (id != null && !seenPromptIds.add(id)) {
    prompt.problem('id', 'duplicate prompt id "$id"');
  }

  final type = prompt.oneOf('type', templatePromptTypes, required: true);
  prompt.text('label', required: true);
  prompt.text('help');

  if (type == 'boolean') {
    prompt.boolean('default');
  } else if (type == 'integer') {
    prompt.integer('default');
  }

  final effect = prompt.oneOf('effect', templatePromptEffects.keys.toSet());
  final effectType = templatePromptEffects[effect];
  if (effectType != null && type != null && type != effectType) {
    prompt.problem('effect', '"$effect" needs a $effectType prompt, not $type');
  }
}

/// Reads typed values from a JSON object, recording problems as it goes.
class _ObjectReader {
  _ObjectReader(this._value, this._path, this._problems) {
    if (_value is! Map<String, Object?>) {
      _problems.add(TemplateProblem(_path, 'must be an object'));
    }
  }

  final Object? _value;
  final String _path;
  final List<TemplateProblem> _problems;

  bool get isObject => _value is Map<String, Object?>;

  bool has(String key) => _map.containsKey(key);

  Map<String, Object?> get _map => _value! as Map<String, Object?>;

  String _childPath(String key) => _path.isEmpty ? key : '$_path.$key';

  void problem(String key, String message) {
    _problems.add(TemplateProblem(_childPath(key), message));
  }

  void allowOnlyKeys(Set<String> keys) {
    for (final key in _map.keys) {
      if (!keys.contains(key)) {
        problem(key, 'unknown key');
      }
    }
  }

  Object? _read(String key, {required bool required}) {
    if (!_map.containsKey(key)) {
      if (required) {
        problem(key, 'is required');
      }
      return null;
    }
    return _map[key];
  }

  T? _typed<T>(String key, String typeName, {required bool required}) {
    final value = _read(key, required: required);
    if (value == null) {
      if (_map.containsKey(key)) {
        problem(key, 'must be $typeName, not null');
      }
      return null;
    }
    if (value is T) {
      return value as T;
    }
    problem(key, 'must be $typeName');
    return null;
  }

  String? text(String key, {bool required = false}) {
    final value = _typed<String>(key, 'a string', required: required);
    if (value != null && value.trim().isEmpty) {
      problem(key, 'must not be empty');
      return null;
    }
    return value;
  }

  int? integer(String key, {bool required = false}) {
    return _typed<int>(key, 'a whole number', required: required);
  }

  bool? boolean(String key, {bool required = false}) {
    return _typed<bool>(key, 'true or false', required: required);
  }

  String? identifier(String key, {bool required = false}) {
    final value = text(key, required: required);
    if (value != null && !_idPattern.hasMatch(value)) {
      problem(
        key,
        '"$value" must use lowercase letters, digits, and single hyphens',
      );
      return null;
    }
    return value;
  }

  String? oneOf(String key, Set<String> allowed, {bool required = false}) {
    final value = text(key, required: required);
    if (value != null && !allowed.contains(value)) {
      problem(
        key,
        'unsupported value "$value"; expected one of: ${allowed.join(', ')}',
      );
      return null;
    }
    return value;
  }

  _ObjectReader? object(String key, {bool required = false}) {
    final value = _read(key, required: required);
    if (value == null && !_map.containsKey(key)) {
      return null;
    }
    final reader = _ObjectReader(value, _childPath(key), _problems);
    return reader.isObject ? reader : null;
  }

  List<_ObjectReader>? list(String key, {bool required = false}) {
    final value = _read(key, required: required);
    if (value == null && !_map.containsKey(key)) {
      return null;
    }
    if (value is! List<Object?>) {
      problem(key, 'must be a list');
      return null;
    }
    return [
      for (var index = 0; index < value.length; index++)
        _ObjectReader(value[index], '${_childPath(key)}[$index]', _problems),
    ];
  }
}
