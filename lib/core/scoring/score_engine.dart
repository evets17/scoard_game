import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/application/models/sessions/quick_score_participant_values.dart';
import 'package:scoard_game/core/formulas/formula_checker.dart';
import 'package:scoard_game/core/formulas/formula_evaluator.dart';
import 'package:scoard_game/core/formulas/formula_parser.dart';

/// Works out every player's calculated fields and score for one round (or
/// the single entry of a final-score game) from what was entered.
///
/// This is the only place that knows how a score is calculated. Results,
/// running totals, sorting, and scenario tests all go through it.
class ScoreEngine {
  ScoreEngine._(this._preset, this._calculated);

  /// The engine for [preset], built once and reused.
  factory ScoreEngine.of(ScoringPreset preset) {
    return _cache[preset] ??= ScoreEngine._build(preset);
  }

  static final _cache = Expando<ScoreEngine>('ScoreEngine');

  factory ScoreEngine._build(ScoringPreset preset) {
    final fieldIds = {
      for (final field in preset.scoreFields) field.id,
      for (final field in preset.calculatedFields) field.id,
    };
    final parsed = <String, Formula>{};
    final dependencies = <String, Set<String>>{};

    for (final field in preset.calculatedFields) {
      final formula = Formula.parse(field.formula);
      final reads = <String>{};
      final problems =
          checkFormula(formula, fieldIds: fieldIds, dependencies: reads);
      if (problems.isNotEmpty) {
        throw StateError(
          '${preset.id}: ${field.id}: ${problems.first}. '
          'Templates are validated when loaded, so this should not happen.',
        );
      }
      parsed[field.id] = formula;
      dependencies[field.id] = reads;
    }

    return ScoreEngine._(preset, [
      for (final id in orderCalculatedFields(dependencies)) (id, parsed[id]!),
    ]);
  }

  final ScoringPreset _preset;

  /// Calculated fields in an order where each comes after what it reads.
  final List<(String, Formula)> _calculated;

  /// Every field's value for each player, keyed by player id.
  Map<String, Map<String, int>> fieldValues(
    List<QuickScoreParticipantValues> participants, {
    required int roundNumber,
  }) {
    final values = {
      for (final participant in participants)
        participant.playerId: <String, int>{
          for (final field in _preset.scoreFields)
            field.id: participant.enteredValues[field.id] ?? 0,
        },
    };
    final builtIns = {
      'playerCount': participants.length,
      'roundNumber': roundNumber,
    };

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
  }) {
    final scoreId = _preset.scoreId;
    return {
      for (final entry
          in fieldValues(participants, roundNumber: roundNumber).entries)
        entry.key: entry.value[scoreId] ?? 0,
    };
  }
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
