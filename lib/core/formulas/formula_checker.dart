import 'package:scoard_game/core/formulas/formula_parser.dart';

/// Where a formula is used, which decides the names and functions it may use.
enum FormulaContext {
  /// A calculated line: reads the player's lines, built-in values, and the
  /// other players through functions.
  line,

  /// A value picker's total: reads the totals of its tile groups.
  picker,

  /// Text a template shows on the player card (score labels, score sub
  /// labels, player badges): reads everything a line formula can, plus the
  /// tile groups of the score's value pickers.
  card,
}

/// Values every line formula can use, like lines. `playerPosition` is the
/// player's place in play order, from 1.
const formulaBuiltIns = {'playerCount', 'roundNumber', 'playerPosition'};

/// Functions that look at the other players. Their one argument is a bare
/// line name, for example `highestOther(inning-points)`.
/// `countOthersAbove` and `countOthersTied` count the other players whose
/// value is higher than, or the same as, this player's.
const otherPlayerFunctions = {
  'highestOther',
  'lowestOther',
  'sumOthers',
  'countOthersAbove',
  'countOthersTied',
};

/// Functions that look at one tile group of a value picker. Their one
/// argument is a bare group name, for example `distinctIn(numbers)`.
const pickerGroupFunctions = {'countIn', 'distinctIn'};

const _commonArity = <String, (int, int?)>{
  'min': (1, null),
  'max': (1, null),
  'abs': (1, 1),
  'if': (3, 3),
};

/// Allowed argument counts per context. Null maximum means any number.
const _arityByContext = <FormulaContext, Map<String, (int, int?)>>{
  FormulaContext.line: {
    ..._commonArity,
    'highestOther': (1, 1),
    'lowestOther': (1, 1),
    'sumOthers': (1, 1),
    'countOthersAbove': (1, 1),
    'countOthersTied': (1, 1),
    'countOthers': (0, 0),
  },
  FormulaContext.picker: {
    ..._commonArity,
    'countIn': (1, 1),
    'distinctIn': (1, 1),
  },
  FormulaContext.card: {
    ..._commonArity,
    'highestOther': (1, 1),
    'lowestOther': (1, 1),
    'sumOthers': (1, 1),
    'countOthersAbove': (1, 1),
    'countOthersTied': (1, 1),
    'countOthers': (0, 0),
    'countIn': (1, 1),
    'distinctIn': (1, 1),
  },
};

class FormulaProblem {
  const FormulaProblem(this.message, this.position);

  final String message;

  /// 1-based character position in the formula.
  final int position;

  @override
  String toString() => '$message at position $position';
}

/// Checks [formula] against the names it may read: the template's lines
/// and [promptIds], or for [FormulaContext.picker] the picker's tile groups
/// (given as [lineIds]). A [FormulaContext.card] also reads [groupIds].
///
/// Returns the problems found, and through [dependencies] the names the
/// formula reads.
List<FormulaProblem> checkFormula(
  Formula formula, {
  required Set<String> lineIds,
  Set<String> promptIds = const {},
  Set<String> groupIds = const {},
  FormulaContext context = FormulaContext.line,
  Set<String>? dependencies,
}) {
  final problems = <FormulaProblem>[];
  final reads = dependencies ?? <String>{};
  final arity = _arityByContext[context]!;
  final builtIns = switch (context) {
    FormulaContext.line => {...formulaBuiltIns, ...promptIds},
    FormulaContext.picker => const <String>{},
    FormulaContext.card => {...formulaBuiltIns, ...promptIds, ...groupIds},
  };

  /// The bare names [function] takes, and what they are called, or null if
  /// it takes values.
  (Set<String>, String)? bareNamesFor(String function) {
    if (context != FormulaContext.picker &&
        otherPlayerFunctions.contains(function)) {
      return (lineIds, 'line');
    }
    if (pickerGroupFunctions.contains(function)) {
      return context == FormulaContext.card
          ? (groupIds, 'group')
          : (lineIds, 'group');
    }
    return null;
  }

  void check(FormulaNode node, {(Set<String>, String)? bareNames}) {
    switch (node) {
      case NumberNode():
        break;
      case ReferenceNode(:final name, :final position):
        if (lineIds.contains(name)) {
          reads.add(name);
        } else if (!builtIns.contains(name)) {
          final known = [...lineIds, ...builtIns];
          problems.add(
            FormulaProblem(
              'unknown name "$name"; expected one of: ${known.join(', ')}',
              position,
            ),
          );
        }
      case FieldNameNode(:final name, :final position):
        if (bareNames == null) {
          problems.add(
            FormulaProblem(
              lineIds.contains(name) || builtIns.contains(name)
                  ? 'use {$name} to read a value'
                  : 'unexpected name "$name"',
              position,
            ),
          );
        } else if (bareNames.$1.contains(name)) {
          reads.add(name);
        } else {
          problems.add(
            FormulaProblem('unknown ${bareNames.$2} "$name"', position),
          );
        }
      case UnaryNode(:final operand):
        check(operand);
      case BinaryNode(:final left, :final right):
        check(left);
        check(right);
      case CallNode(:final name, :final arguments, :final position):
        final range = arity[name];
        if (range == null) {
          problems.add(
            FormulaProblem(
              'unknown function "$name"; expected one of: '
              '${arity.keys.join(', ')}',
              position,
            ),
          );
          return;
        }

        final (minimum, maximum) = range;
        if (arguments.length < minimum ||
            (maximum != null && arguments.length > maximum)) {
          final expected = maximum == null
              ? 'at least $minimum'
              : minimum == maximum
                  ? '$minimum'
                  : '$minimum to $maximum';
          problems.add(
            FormulaProblem(
              '$name takes $expected argument${(maximum ?? minimum) == 1 ? '' : 's'}, '
              'not ${arguments.length}',
              position,
            ),
          );
        }

        final bareNames = bareNamesFor(name);
        for (final argument in arguments) {
          if (bareNames != null && argument is! FieldNameNode) {
            final (names, kind) = bareNames;
            problems.add(
              FormulaProblem(
                '$name needs a $kind name without braces, for example '
                '$name(${names.isEmpty ? 'points' : names.first})',
                argument.position,
              ),
            );
            continue;
          }
          check(argument, bareNames: bareNames);
        }
    }
  }

  check(formula.root);
  return problems;
}
