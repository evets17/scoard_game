import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/core/scoring/score_expression.dart';

void main() {
  ScoreExpression type(String keys) {
    var expression = const ScoreExpression();
    for (final key in keys.split(' ')) {
      expression = switch (key) {
        '+' => expression.applyOperator(ScoreOperator.add),
        '-' => expression.applyOperator(ScoreOperator.subtract),
        '*' => expression.applyOperator(ScoreOperator.multiply),
        '/' => expression.applyOperator(ScoreOperator.divide),
        '±' => expression.toggleSign(),
        '<' => expression.backspace(),
        _ => key.split('').fold(expression, (e, digit) => e.appendDigit(digit)),
      };
    }
    return expression;
  }

  test('a single number works like a plain entry', () {
    final expression = type('42');

    expect(expression.value, 42);
    expect(expression.hasOperator, isFalse);
    expect(expression.displayText, '42');
  });

  test('evaluates left to right as a running tally', () {
    final expression = type('3 + 4 + 5 * 2');

    expect(expression.value, 24);
    expect(expression.displayText, '3 + 4 + 5 × 2');
  });

  test('subtracts', () {
    expect(type('20 - 7').value, 13);
  });

  test('division rounds down', () {
    expect(type('10 / 3').value, 3);
    expect(type('± 7 / 2').value, -4);
  });

  test('division by zero has no value and is flagged', () {
    final expression = type('10 / 0');

    expect(expression.value, isNull);
    expect(expression.dividesByZero, isTrue);
  });

  test('operators before any number are ignored', () {
    final expression = type('+ * 5');

    expect(expression.value, 5);
    expect(expression.displayText, '5');
  });

  test('a second operator replaces the first', () {
    final expression = type('6 + * 2');

    expect(expression.value, 12);
    expect(expression.displayText, '6 × 2');
  });

  test('a trailing operator is ignored', () {
    final expression = type('3 + 4 +');

    expect(expression.value, 7);
    expect(expression.displayText, '3 + 4 +');
  });

  test('sign toggle makes the current number negative', () {
    expect(type('5 ±').value, -5);
    expect(type('10 + 3 ±').value, 7);
    expect(type('10 + 3 ±').displayText, '10 + (-3)');
  });

  test('backspace removes digits, then operators', () {
    expect(type('12 + 34 <').displayText, '12 + 3');
    expect(type('12 + 3 < <').displayText, '12');
    expect(type('12 + 3 < <').hasOperator, isFalse);
    expect(type('5 < <').isEmpty, isTrue);
  });

  test('leading zeros are dropped', () {
    expect(type('0 0 7').displayText, '7');
  });

  test('nothing entered has no value', () {
    expect(const ScoreExpression().value, isNull);
    expect(const ScoreExpression().displayText, '0');
  });
}
