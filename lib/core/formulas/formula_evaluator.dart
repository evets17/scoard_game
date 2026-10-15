import 'package:scoard_game/core/formulas/formula_parser.dart';

/// The values a formula can see while it is evaluated. A line formula sees
/// one player's lines and the other players; a picker total sees its tile
/// groups.
abstract class FormulaScope {
  /// A line's value, a built-in value, or a tile group's total.
  int valueOf(String name);

  /// The other players' values for a line.
  List<int> otherValuesOf(String lineId) => const [];

  /// How many other players there are.
  int get otherPlayerCount => 0;

  /// How many tiles were picked from a group.
  int countIn(String groupId) => 0;

  /// How many different tiles were picked from a group.
  int distinctIn(String groupId) => 0;
}

/// Evaluates a checked formula. Arithmetic is whole-number; division rounds
/// down, and dividing by zero gives 0. True is 1 and false is 0.
int evaluateFormula(Formula formula, FormulaScope scope) {
  return _evaluate(formula.root, scope);
}

int _evaluate(FormulaNode node, FormulaScope scope) {
  switch (node) {
    case NumberNode(:final value):
      return value;
    case ReferenceNode(:final name):
      return scope.valueOf(name);
    case FieldNameNode():
      // Only reachable inside other-player functions, handled below.
      return 0;
    case UnaryNode(:final operator, :final operand):
      final value = _evaluate(operand, scope);
      return operator == 'not' ? _bool(value == 0) : -value;
    case BinaryNode(:final operator, :final left, :final right):
      if (operator == 'and') {
        return _bool(_evaluate(left, scope) != 0 && _evaluate(right, scope) != 0);
      }
      if (operator == 'or') {
        return _bool(_evaluate(left, scope) != 0 || _evaluate(right, scope) != 0);
      }
      final a = _evaluate(left, scope);
      final b = _evaluate(right, scope);
      return switch (operator) {
        '+' => a + b,
        '-' => a - b,
        '*' => a * b,
        '/' => _divideRoundingDown(a, b),
        '%' => _remainder(a, b),
        '>' => _bool(a > b),
        '>=' => _bool(a >= b),
        '<' => _bool(a < b),
        '<=' => _bool(a <= b),
        '==' => _bool(a == b),
        '!=' => _bool(a != b),
        _ => throw StateError('Unknown operator $operator'),
      };
    case CallNode(:final name, :final arguments):
      return _call(name, arguments, scope);
  }
}

int _call(String name, List<FormulaNode> arguments, FormulaScope scope) {
  List<int> values() => [for (final a in arguments) _evaluate(a, scope)];
  List<int> others() => scope.otherValuesOf(_lineName(arguments));

  switch (name) {
    case 'min':
      return values().reduce((a, b) => a < b ? a : b);
    case 'max':
      return values().reduce((a, b) => a > b ? a : b);
    case 'abs':
      return _evaluate(arguments.single, scope).abs();
    case 'if':
      return _evaluate(arguments[0], scope) != 0
          ? _evaluate(arguments[1], scope)
          : _evaluate(arguments[2], scope);
    case 'highestOther':
      final values = others();
      return values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);
    case 'lowestOther':
      final values = others();
      return values.isEmpty ? 0 : values.reduce((a, b) => a < b ? a : b);
    case 'sumOthers':
      return others().fold(0, (sum, value) => sum + value);
    case 'countOthersAbove':
      final mine = scope.valueOf(_lineName(arguments));
      return others().where((value) => value > mine).length;
    case 'countOthersTied':
      final mine = scope.valueOf(_lineName(arguments));
      return others().where((value) => value == mine).length;
    case 'countOthers':
      return scope.otherPlayerCount;
    case 'countIn':
      return scope.countIn((arguments.single as FieldNameNode).name);
    case 'distinctIn':
      return scope.distinctIn((arguments.single as FieldNameNode).name);
    default:
      throw StateError('Unknown function $name');
  }
}

String _lineName(List<FormulaNode> arguments) =>
    (arguments.single as FieldNameNode).name;

int _bool(bool value) => value ? 1 : 0;

int _divideRoundingDown(int left, int right) {
  if (right == 0) {
    return 0;
  }
  final quotient = left ~/ right;
  final hasRemainder = quotient * right != left;
  return hasRemainder && (left < 0) != (right < 0) ? quotient - 1 : quotient;
}

/// What is left after dividing, matching `/`, which rounds down: so
/// `a == (a / b) * b + a % b`. With a positive [right] it is never negative,
/// and dividing by zero gives 0.
int _remainder(int left, int right) {
  if (right == 0) {
    return 0;
  }
  return left - _divideRoundingDown(left, right) * right;
}
