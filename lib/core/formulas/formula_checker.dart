import 'package:scoard_game/core/formulas/formula_parser.dart';

/// Values every formula can use, like fields.
const formulaBuiltIns = {'playerCount', 'roundNumber'};

/// Functions that look at the other players. Their one argument is a bare
/// field name, for example `highestOther(inning-points)`.
const otherPlayerFunctions = {'highestOther', 'lowestOther', 'sumOthers'};

/// Allowed argument counts. Null maximum means any number.
const _functionArity = <String, (int, int?)>{
  'min': (1, null),
  'max': (1, null),
  'abs': (1, 1),
  'if': (3, 3),
  'highestOther': (1, 1),
  'lowestOther': (1, 1),
  'sumOthers': (1, 1),
  'countOthers': (0, 0),
};

class FormulaProblem {
  const FormulaProblem(this.message, this.position);

  final String message;

  /// 1-based character position in the formula.
  final int position;

  @override
  String toString() => '$message at position $position';
}

/// Checks [formula] against the template's [fieldIds].
///
/// Returns the problems found, and through [dependencies] the field ids the
/// formula reads, whether this player's or the other players'.
List<FormulaProblem> checkFormula(
  Formula formula, {
  required Set<String> fieldIds,
  Set<String>? dependencies,
}) {
  final problems = <FormulaProblem>[];
  final reads = dependencies ?? <String>{};

  void check(FormulaNode node, {bool fieldNameAllowed = false}) {
    switch (node) {
      case NumberNode():
        break;
      case ReferenceNode(:final name, :final position):
        if (fieldIds.contains(name)) {
          reads.add(name);
        } else if (!formulaBuiltIns.contains(name)) {
          problems.add(FormulaProblem(_unknownName(name, fieldIds), position));
        }
      case FieldNameNode(:final name, :final position):
        if (!fieldNameAllowed) {
          problems.add(
            FormulaProblem(
              fieldIds.contains(name) || formulaBuiltIns.contains(name)
                  ? 'use {$name} to read a value'
                  : 'unexpected name "$name"',
              position,
            ),
          );
        } else if (fieldIds.contains(name)) {
          reads.add(name);
        } else {
          problems.add(FormulaProblem('unknown field "$name"', position));
        }
      case UnaryNode(:final operand):
        check(operand);
      case BinaryNode(:final left, :final right):
        check(left);
        check(right);
      case CallNode(:final name, :final arguments, :final position):
        final arity = _functionArity[name];
        if (arity == null) {
          problems.add(
            FormulaProblem(
              'unknown function "$name"; expected one of: '
              '${_functionArity.keys.join(', ')}',
              position,
            ),
          );
          return;
        }

        final (minimum, maximum) = arity;
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

        final takesFieldName = otherPlayerFunctions.contains(name);
        for (final argument in arguments) {
          if (takesFieldName && argument is! FieldNameNode) {
            problems.add(
              FormulaProblem(
                '$name needs a field name without braces, for example '
                '$name(${fieldIds.isEmpty ? 'points' : fieldIds.first})',
                argument.position,
              ),
            );
            continue;
          }
          check(argument, fieldNameAllowed: takesFieldName);
        }
    }
  }

  check(formula.root);
  return problems;
}

String _unknownName(String name, Set<String> fieldIds) {
  final known = [...fieldIds, ...formulaBuiltIns];
  return 'unknown name "$name"; expected one of: ${known.join(', ')}';
}
