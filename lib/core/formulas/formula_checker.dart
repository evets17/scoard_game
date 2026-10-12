import 'package:scoard_game/core/formulas/formula_parser.dart';

/// Where a formula is used, which decides the names and functions it may use.
enum FormulaContext {
  /// A calculated field: reads the player's fields, built-in values, and the
  /// other players through functions.
  field,

  /// A value picker's total: reads the totals of its tile groups.
  picker,
}

/// Values every field formula can use, like fields.
const formulaBuiltIns = {'playerCount', 'roundNumber'};

/// Functions that look at the other players. Their one argument is a bare
/// field name, for example `highestOther(inning-points)`.
const otherPlayerFunctions = {'highestOther', 'lowestOther', 'sumOthers'};

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
  FormulaContext.field: {
    ..._commonArity,
    'highestOther': (1, 1),
    'lowestOther': (1, 1),
    'sumOthers': (1, 1),
    'countOthers': (0, 0),
  },
  FormulaContext.picker: {
    ..._commonArity,
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

/// Checks [formula] against the names it may read: the template's fields,
/// or for [FormulaContext.picker] the picker's tile groups.
///
/// Returns the problems found, and through [dependencies] the names the
/// formula reads.
List<FormulaProblem> checkFormula(
  Formula formula, {
  required Set<String> fieldIds,
  FormulaContext context = FormulaContext.field,
  Set<String>? dependencies,
}) {
  final problems = <FormulaProblem>[];
  final reads = dependencies ?? <String>{};
  final arity = _arityByContext[context]!;
  final builtIns =
      context == FormulaContext.field ? formulaBuiltIns : const <String>{};
  final bareNameFunctions = context == FormulaContext.field
      ? otherPlayerFunctions
      : pickerGroupFunctions;
  final nameKind = context == FormulaContext.field ? 'field' : 'group';

  void check(FormulaNode node, {bool fieldNameAllowed = false}) {
    switch (node) {
      case NumberNode():
        break;
      case ReferenceNode(:final name, :final position):
        if (fieldIds.contains(name)) {
          reads.add(name);
        } else if (!builtIns.contains(name)) {
          final known = [...fieldIds, ...builtIns];
          problems.add(
            FormulaProblem(
              'unknown name "$name"; expected one of: ${known.join(', ')}',
              position,
            ),
          );
        }
      case FieldNameNode(:final name, :final position):
        if (!fieldNameAllowed) {
          problems.add(
            FormulaProblem(
              fieldIds.contains(name) || builtIns.contains(name)
                  ? 'use {$name} to read a value'
                  : 'unexpected name "$name"',
              position,
            ),
          );
        } else if (fieldIds.contains(name)) {
          reads.add(name);
        } else {
          problems.add(FormulaProblem('unknown $nameKind "$name"', position));
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

        final takesName = bareNameFunctions.contains(name);
        for (final argument in arguments) {
          if (takesName && argument is! FieldNameNode) {
            problems.add(
              FormulaProblem(
                '$name needs a $nameKind name without braces, for example '
                '$name(${fieldIds.isEmpty ? 'points' : fieldIds.first})',
                argument.position,
              ),
            );
            continue;
          }
          check(argument, fieldNameAllowed: takesName);
        }
    }
  }

  check(formula.root);
  return problems;
}
