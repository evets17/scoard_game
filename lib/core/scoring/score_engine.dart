import 'package:scoard_game/application/models/scoring/score_note_definition.dart';
import 'package:scoard_game/application/models/scoring/score_row_label.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/application/models/sessions/quick_score_participant_values.dart';
import 'package:scoard_game/core/formulas/formula_checker.dart';
import 'package:scoard_game/core/formulas/formula_evaluator.dart';
import 'package:scoard_game/core/formulas/formula_parser.dart';
import 'package:scoard_game/core/scoring/score_note_text.dart';
import 'package:scoard_game/core/scoring/value_picker_total.dart';

/// Works out every player's calculated fields and score for one round (or
/// the single entry of a final-score game) from what was entered.
///
/// This is the only place that knows how a score is calculated. Results,
/// running totals, sorting, and scenario tests all go through it.
class ScoreEngine {
  ScoreEngine._(this._preset, this._calculated, this._notes, this._groupIds);

  /// The engine for [preset], built once and reused.
  factory ScoreEngine.of(ScoringPreset preset) {
    return _cache[preset] ??= ScoreEngine._build(preset);
  }

  static final _cache = Expando<ScoreEngine>('ScoreEngine');

  factory ScoreEngine._build(ScoringPreset preset) {
    final fieldIds = {
      for (final field in preset.scoreFields) field.id,
      for (final field in preset.markerFields) field.id,
      for (final field in preset.calculatedFields) field.id,
    };
    final promptIds = {
      for (final prompt in preset.promptDefinitions) prompt.id,
    };
    final parsed = <String, Formula>{};
    final dependencies = <String, Set<String>>{};

    for (final field in preset.calculatedFields) {
      final formula = Formula.parse(field.formula);
      final reads = <String>{};
      final problems = checkFormula(
        formula,
        fieldIds: fieldIds,
        promptIds: promptIds,
        dependencies: reads,
      );
      if (problems.isNotEmpty) {
        throw StateError(
          '${preset.id}: ${field.id}: ${problems.first}. '
          'Templates are validated when loaded, so this should not happen.',
        );
      }
      parsed[field.id] = formula;
      dependencies[field.id] = reads;
    }

    final groupIds = {
      for (final picker in preset.scoreFields.first.valuePickers)
        for (final option in picker.options)
          if (option.groupId case final String groupId) groupId,
    };
    final notes = <(ScoreNoteDefinition, Formula)>[];
    for (final note in preset.scoreNotes) {
      final formula = Formula.parse(note.when);
      final problems = checkFormula(
        formula,
        fieldIds: fieldIds,
        promptIds: promptIds,
        groupIds: groupIds,
        context: FormulaContext.note,
      );
      if (problems.isNotEmpty) {
        throw StateError(
          '${preset.id}: score note "${note.text}": ${problems.first}. '
          'Templates are validated when loaded, so this should not happen.',
        );
      }
      notes.add((note, formula));
    }

    return ScoreEngine._(
      preset,
      [
        for (final id in orderCalculatedFields(dependencies)) (id, parsed[id]!),
      ],
      notes,
      groupIds,
    );
  }

  final ScoringPreset _preset;

  /// Calculated fields in an order where each comes after what it reads.
  final List<(String, Formula)> _calculated;

  final List<(ScoreNoteDefinition, Formula)> _notes;

  /// Tile groups of the score's value pickers, which notes can read.
  final Set<String> _groupIds;

  /// Every field's value for each player, keyed by player id.
  ///
  /// [options] are the game's prompt answers by prompt id, as
  /// `ResolvedPresetOptions.formulaValues` gives them.
  Map<String, Map<String, int>> fieldValues(
    List<QuickScoreParticipantValues> participants, {
    required int roundNumber,
    Map<String, int> options = const {},
  }) {
    final values = {
      for (final participant in participants)
        participant.playerId: <String, int>{
          for (final field in _preset.scoreFields)
            field.id: participant.enteredValues[field.id] ?? 0,
          for (final marker in _preset.markerFields)
            marker.id: participant.enteredValues[marker.id] ?? 0,
        },
    };
    final builtIns = _builtIns(participants, roundNumber, options);

    // One field at a time across every player, so a formula that reads the
    // other players always sees finished values.
    for (final (fieldId, formula) in _calculated) {
      final results = <String, int>{};
      for (final participant in participants) {
        results[participant.playerId] = evaluateFormula(
          formula,
          _PlayerScope(participant.playerId, values, builtIns),
        );
      }
      for (final entry in results.entries) {
        values[entry.key]![fieldId] = entry.value;
      }
    }

    return values;
  }

  /// Each player's score, keyed by player id.
  Map<String, int> scores(
    List<QuickScoreParticipantValues> participants, {
    required int roundNumber,
    Map<String, int> options = const {},
  }) {
    final scoreId = _preset.scoreId;
    return {
      for (final entry in fieldValues(
        participants,
        roundNumber: roundNumber,
        options: options,
      ).entries)
        entry.key: entry.value[scoreId] ?? 0,
    };
  }

  /// Each player's score note, keyed by player id: the first of the
  /// template's notes whose `when` is true, with its `{name}`s filled in.
  /// Players with no note are left out.
  Map<String, ScoreRowLabel> scoreNotes(
    List<QuickScoreParticipantValues> participants, {
    required int roundNumber,
    Map<String, int> options = const {},
  }) {
    if (_notes.isEmpty) {
      return const {};
    }

    final values =
        fieldValues(participants, roundNumber: roundNumber, options: options);
    final builtIns = _builtIns(participants, roundNumber, options);
    final notes = <String, ScoreRowLabel>{};
    for (final participant in participants) {
      final scope = _NoteScope(
        _PlayerScope(participant.playerId, values, builtIns),
        _pickedTiles(participant),
        _groupIds,
      );
      for (final (note, formula) in _notes) {
        if (evaluateFormula(formula, scope) != 0) {
          notes[participant.playerId] = ScoreRowLabel(
            text: fillScoreNoteText(note.text, scope.valueOf),
            color: note.color,
          );
          break;
        }
      }
    }
    return notes;
  }

  /// The tiles the player picked for the score, if it was entered with a
  /// value picker.
  FormulaScope? _pickedTiles(QuickScoreParticipantValues participant) {
    final field = _preset.scoreFields.first;
    final pick = participant.entryPicks[field.id];
    if (pick == null) {
      return null;
    }
    final picker = field.valuePickers
        .where((picker) => picker.id == pick.pickerId)
        .firstOrNull;
    return picker == null
        ? null
        : pickedTileGroupsScope(picker, pickedIndexesFor(picker, pick));
  }

  static Map<String, int> _builtIns(
    List<QuickScoreParticipantValues> participants,
    int roundNumber,
    Map<String, int> options,
  ) {
    return {
      ...options,
      'playerCount': participants.length,
      'roundNumber': roundNumber,
    };
  }
}

/// What a score note reads: the player's fields, built-in values, and the
/// other players, plus the tile groups picked for the score.
class _NoteScope extends FormulaScope {
  _NoteScope(this._player, this._tiles, this._groupIds);

  final _PlayerScope _player;
  final FormulaScope? _tiles;
  final Set<String> _groupIds;

  @override
  int valueOf(String name) => _groupIds.contains(name)
      ? _tiles?.valueOf(name) ?? 0
      : _player.valueOf(name);

  @override
  List<int> otherValuesOf(String fieldId) => _player.otherValuesOf(fieldId);

  @override
  int get otherPlayerCount => _player.otherPlayerCount;

  @override
  int countIn(String groupId) => _tiles?.countIn(groupId) ?? 0;

  @override
  int distinctIn(String groupId) => _tiles?.distinctIn(groupId) ?? 0;
}

class _PlayerScope extends FormulaScope {
  _PlayerScope(this._playerId, this._values, this._builtIns);

  final String _playerId;
  final Map<String, Map<String, int>> _values;
  final Map<String, int> _builtIns;

  @override
  int valueOf(String name) =>
      _values[_playerId]![name] ?? _builtIns[name] ?? 0;

  @override
  List<int> otherValuesOf(String fieldId) => [
        for (final entry in _values.entries)
          if (entry.key != _playerId) entry.value[fieldId] ?? 0,
      ];

  @override
  int get otherPlayerCount => _values.length - 1;
}

/// Orders calculated fields so each comes after the calculated fields it
/// reads. [dependencies] maps each calculated field to every field it reads.
///
/// Throws [CircularFormulaError] naming the loop if there is one.
List<String> orderCalculatedFields(Map<String, Set<String>> dependencies) {
  final ordered = <String>[];
  final done = <String>{};
  final visiting = <String>[];

  void visit(String id) {
    if (done.contains(id)) {
      return;
    }
    final loopStart = visiting.indexOf(id);
    if (loopStart >= 0) {
      throw CircularFormulaError([...visiting.sublist(loopStart), id]);
    }
    visiting.add(id);
    for (final dependency in dependencies[id]!) {
      if (dependencies.containsKey(dependency)) {
        visit(dependency);
      }
    }
    visiting.removeLast();
    done.add(id);
    ordered.add(id);
  }

  for (final id in dependencies.keys) {
    visit(id);
  }
  return ordered;
}

class CircularFormulaError extends Error {
  CircularFormulaError(this.loop);

  /// The fields in the loop, ending where it started, for example
  /// `[a, b, a]`.
  final List<String> loop;

  @override
  String toString() => 'circular reference: ${loop.join(' -> ')}';
}
