import 'package:scoard_game/application/models/scoring/card_text.dart';
import 'package:scoard_game/application/models/scoring/card_text_definition.dart';
import 'package:scoard_game/application/models/scoring/scoring_preset.dart';
import 'package:scoard_game/application/models/sessions/quick_score_participant_values.dart';
import 'package:scoard_game/core/formulas/formula_checker.dart';
import 'package:scoard_game/core/formulas/formula_evaluator.dart';
import 'package:scoard_game/core/formulas/formula_parser.dart';
import 'package:scoard_game/core/scoring/card_text_values.dart';
import 'package:scoard_game/core/scoring/value_picker_total.dart';

/// Works out every player's calculated lines and score for one round (or
/// the single entry of a final-score game) from what was entered, and the
/// text the template shows on each player's card.
///
/// This is the only place that knows how a score is calculated. Results,
/// running totals, sorting, and scenario tests all go through it.
///
/// Participants are always given in play order, which is where
/// `{playerPosition}` comes from.
class ScoreEngine {
  ScoreEngine._(
    this._preset,
    this._calculated,
    this._scoreLabels,
    this._scoreSubLabels,
    this._playerBadges,
    this._groupIds,
  );

  /// The engine for [preset], built once and reused.
  factory ScoreEngine.of(ScoringPreset preset) {
    return _cache[preset] ??= ScoreEngine._build(preset);
  }

  static final _cache = Expando<ScoreEngine>('ScoreEngine');

  factory ScoreEngine._build(ScoringPreset preset) {
    final lineIds = {
      for (final line in preset.enteredLines) line.id,
      for (final line in preset.markerLines) line.id,
      for (final line in preset.calculatedLines) line.id,
    };
    final promptIds = {
      for (final prompt in preset.promptDefinitions) prompt.id,
    };
    final parsed = <String, Formula>{};
    final dependencies = <String, Set<String>>{};

    for (final line in preset.calculatedLines) {
      final formula = Formula.parse(line.formula);
      final reads = <String>{};
      final problems = checkFormula(
        formula,
        lineIds: lineIds,
        promptIds: promptIds,
        dependencies: reads,
      );
      if (problems.isNotEmpty) {
        throw StateError(
          '${preset.id}: ${line.id}: ${problems.first}. '
          'Templates are validated when loaded, so this should not happen.',
        );
      }
      parsed[line.id] = formula;
      dependencies[line.id] = reads;
    }

    final groupIds = {
      for (final picker in preset.enteredLines.first.valuePickers)
        for (final option in picker.options)
          if (option.groupId case final String groupId) groupId,
    };
    List<(CardTextDefinition, Formula)> parseCardTexts(
      List<CardTextDefinition> definitions,
    ) {
      return [
        for (final definition in definitions)
          () {
            final formula = Formula.parse(definition.when);
            final problems = checkFormula(
              formula,
              lineIds: lineIds,
              promptIds: promptIds,
              groupIds: groupIds,
              context: FormulaContext.card,
            );
            if (problems.isNotEmpty) {
              throw StateError(
                '${preset.id}: "${definition.text}": ${problems.first}. '
                'Templates are validated when loaded, so this should not '
                'happen.',
              );
            }
            return (definition, formula);
          }(),
      ];
    }

    return ScoreEngine._(
      preset,
      [
        for (final id in orderCalculatedLines(dependencies)) (id, parsed[id]!),
      ],
      parseCardTexts(preset.scoreLabels),
      parseCardTexts(preset.scoreSubLabels),
      parseCardTexts(preset.playerBadges),
      groupIds,
    );
  }

  final ScoringPreset _preset;

  /// Calculated lines in an order where each comes after what it reads.
  final List<(String, Formula)> _calculated;

  final List<(CardTextDefinition, Formula)> _scoreLabels;
  final List<(CardTextDefinition, Formula)> _scoreSubLabels;
  final List<(CardTextDefinition, Formula)> _playerBadges;

  /// Tile groups of the score's value pickers, which card text can read.
  final Set<String> _groupIds;

  bool get hasCardTexts =>
      _scoreLabels.isNotEmpty ||
      _scoreSubLabels.isNotEmpty ||
      _playerBadges.isNotEmpty;

  /// Every line's value for each player, keyed by player id.
  ///
  /// [options] are the game's prompt answers by prompt id, as
  /// `ResolvedPresetOptions.formulaValues` gives them.
  Map<String, Map<String, int>> lineValues(
    List<QuickScoreParticipantValues> participants, {
    required int roundNumber,
    Map<String, int> options = const {},
  }) {
    final values = {
      for (final participant in participants)
        participant.playerId: <String, int>{
          for (final line in _preset.enteredLines)
            line.id: participant.enteredValues[line.id] ?? 0,
          for (final marker in _preset.markerLines)
            marker.id: participant.enteredValues[marker.id] ?? 0,
        },
    };
    final builtIns = _builtIns(participants, roundNumber, options);

    // One line at a time across every player, so a formula that reads the
    // other players always sees finished values.
    for (final (lineId, formula) in _calculated) {
      final results = <String, int>{};
      for (final (index, participant) in participants.indexed) {
        results[participant.playerId] = evaluateFormula(
          formula,
          _PlayerScope(participant.playerId, index + 1, values, builtIns),
        );
      }
      for (final entry in results.entries) {
        values[entry.key]![lineId] = entry.value;
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
      for (final entry in lineValues(
        participants,
        roundNumber: roundNumber,
        options: options,
      ).entries)
        entry.key: entry.value[scoreId] ?? 0,
    };
  }

  /// What the template shows on each player's card, keyed by player id: the
  /// first score label and score sub label that apply, and every player
  /// badge that applies, with their `{name}`s filled in.
  Map<String, PlayerCardTexts> cardTexts(
    List<QuickScoreParticipantValues> participants, {
    required int roundNumber,
    Map<String, int> options = const {},
  }) {
    if (!hasCardTexts) {
      return {
        for (final participant in participants)
          participant.playerId: PlayerCardTexts.none,
      };
    }

    final values =
        lineValues(participants, roundNumber: roundNumber, options: options);
    final builtIns = _builtIns(participants, roundNumber, options);
    final texts = <String, PlayerCardTexts>{};
    for (final (index, participant) in participants.indexed) {
      final scope = _CardScope(
        _PlayerScope(participant.playerId, index + 1, values, builtIns),
        _pickedTiles(participant),
        _groupIds,
      );
      Iterable<CardText> matching(
        List<(CardTextDefinition, Formula)> definitions,
      ) sync* {
        for (final (definition, formula) in definitions) {
          if (evaluateFormula(formula, scope) != 0) {
            yield CardText(
              text: fillCardText(definition.text, scope.valueOf),
              color: definition.color,
              size: definition.size,
            );
          }
        }
      }

      texts[participant.playerId] = PlayerCardTexts(
        scoreLabel: matching(_scoreLabels).firstOrNull,
        scoreSubLabel: matching(_scoreSubLabels).firstOrNull,
        playerBadges: matching(_playerBadges).toList(growable: false),
      );
    }
    return texts;
  }

  /// The tiles the player picked for the score, if it was entered with a
  /// value picker.
  FormulaScope? _pickedTiles(QuickScoreParticipantValues participant) {
    final line = _preset.enteredLines.first;
    final pick = participant.entryPicks[line.id];
    if (pick == null) {
      return null;
    }
    final picker = line.valuePickers
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

/// What card text reads: the player's lines, built-in values, and the
/// other players, plus the tile groups picked for the score.
class _CardScope extends FormulaScope {
  _CardScope(this._player, this._tiles, this._groupIds);

  final _PlayerScope _player;
  final FormulaScope? _tiles;
  final Set<String> _groupIds;

  @override
  int valueOf(String name) => _groupIds.contains(name)
      ? _tiles?.valueOf(name) ?? 0
      : _player.valueOf(name);

  @override
  List<int> otherValuesOf(String lineId) => _player.otherValuesOf(lineId);

  @override
  int get otherPlayerCount => _player.otherPlayerCount;

  @override
  int countIn(String groupId) => _tiles?.countIn(groupId) ?? 0;

  @override
  int distinctIn(String groupId) => _tiles?.distinctIn(groupId) ?? 0;
}

class _PlayerScope extends FormulaScope {
  _PlayerScope(this._playerId, this._position, this._values, this._builtIns);

  final String _playerId;

  /// Place in play order, from 1.
  final int _position;
  final Map<String, Map<String, int>> _values;
  final Map<String, int> _builtIns;

  @override
  int valueOf(String name) => name == 'playerPosition'
      ? _position
      : _values[_playerId]![name] ?? _builtIns[name] ?? 0;

  @override
  List<int> otherValuesOf(String lineId) => [
        for (final entry in _values.entries)
          if (entry.key != _playerId) entry.value[lineId] ?? 0,
      ];

  @override
  int get otherPlayerCount => _values.length - 1;
}

/// Orders calculated lines so each comes after the calculated lines it
/// reads. [dependencies] maps each calculated line to every line it reads.
///
/// Throws [CircularFormulaError] naming the loop if there is one.
List<String> orderCalculatedLines(Map<String, Set<String>> dependencies) {
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

  /// The lines in the loop, ending where it started, for example
  /// `[a, b, a]`.
  final List<String> loop;

  @override
  String toString() => 'circular reference: ${loop.join(' -> ')}';
}
