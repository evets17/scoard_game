import 'package:flutter_test/flutter_test.dart';
import 'package:scoard_game/core/formulas/formula_checker.dart';
import 'package:scoard_game/core/formulas/formula_evaluator.dart';
import 'package:scoard_game/core/formulas/formula_parser.dart';

class _Scope extends FormulaScope {
  _Scope(this.own, {this.others = const {}, this.otherCount = 0});

  final Map<String, int> own;
  final Map<String, List<int>> others;
  final int otherCount;

  @override
  int valueOf(String name) => own[name] ?? 0;

  @override
  List<int> otherValuesOf(String lineId) => others[lineId] ?? const [];

  @override
  int get otherPlayerCount => otherCount;
}

void main() {
  int eval(
    String source, {
    Map<String, int> own = const {},
    Map<String, List<int>> others = const {},
    int otherCount = 0,
  }) {
    return evaluateFormula(
      Formula.parse(source),
      _Scope(own, others: others, otherCount: otherCount),
    );
  }

  group('arithmetic', () {
    test('uses normal precedence and parentheses', () {
      expect(eval('3 + 4 * 2'), 11);
      expect(eval('(3 + 4) * 2'), 14);
      expect(eval('10 - 4 - 3'), 3);
      expect(eval('-2 * -3'), 6);
      expect(eval('2 - -3'), 5);
    });

    test('division rounds down and dividing by zero gives 0', () {
      expect(eval('7 / 2'), 3);
      expect(eval('-7 / 2'), -4);
      expect(eval('5 / 0'), 0);
    });

    test('remainder matches division and wraps seats round', () {
      expect(eval('7 % 3'), 1);
      expect(eval('6 % 3'), 0);
      // Like / rounding down, so a positive divisor never gives a negative.
      expect(eval('-1 % 4'), 3);
      expect(eval('5 % 0'), 0);
      expect(eval('2 * 5 % 3'), 1);
      // Who goes first in each round with 4 players: 1, 2, 3, 4, then 1.
      expect(
        [
          for (var round = 1; round <= 5; round++)
            eval('({roundNumber} - 1) % 4 + 1', own: {'roundNumber': round}),
        ],
        [1, 2, 3, 4, 1],
      );
    });
  });

  group('comparison and logic', () {
    test('comparisons give 1 or 0', () {
      expect(eval('3 > 2'), 1);
      expect(eval('3 >= 4'), 0);
      expect(eval('2 == 2'), 1);
      expect(eval('2 != 2'), 0);
      expect(eval('1 + 1 == 2'), 1);
    });

    test('and, or, not', () {
      expect(eval('1 > 0 and 2 > 1'), 1);
      expect(eval('1 > 2 or 2 > 1'), 1);
      expect(eval('not 1 > 2'), 1);
      expect(eval('not 0 or 0'), 1);
    });
  });

  group('functions', () {
    test('min, max, abs, if', () {
      expect(eval('min(4, 2, 9)'), 2);
      expect(eval('max(0, 3 - 7)'), 0);
      expect(eval('abs(-5)'), 5);
      expect(eval('if({a} > 10, 1, 2)', own: {'a': 12}), 1);
      expect(eval('if({a} > 10, 1, 2)', own: {'a': 3}), 2);
    });

    test('lines and built-ins are read through braces', () {
      expect(
        eval('{inning-points} * {roundNumber}', own: {
          'inning-points': 4,
          'roundNumber': 3,
        }),
        12,
      );
    });

    test('other-player functions', () {
      final others = {
        'points': [3, 9, 5],
      };
      expect(eval('highestOther(points)', others: others), 9);
      expect(eval('lowestOther(points)', others: others), 3);
      expect(eval('sumOthers(points)', others: others), 17);
      expect(eval('countOthers()', otherCount: 3), 3);
      expect(eval('countOthersAbove(points)', own: {'points': 5}, others: others), 1);
      expect(eval('countOthersTied(points)', own: {'points': 5}, others: others), 1);
      expect(eval('countOthersAbove(points)', own: {'points': 9}, others: others), 0);
      expect(eval('countOthersTied(points)', own: {'points': 4}, others: others), 0);
      expect(eval('highestOther(points)'), 0);
    });

    test('Cornhole cancellation scoring', () {
      const score = 'max(0, {points} - highestOther(points))';
      expect(eval(score, own: {'points': 7}, others: {'points': [4]}), 3);
      expect(eval(score, own: {'points': 4}, others: {'points': [7]}), 0);
      expect(eval(score, own: {'points': 5}, others: {'points': [5]}), 0);
    });
  });

  group('syntax errors give positions', () {
    FormulaSyntaxError errorFor(String source) {
      try {
        Formula.parse(source);
      } on FormulaSyntaxError catch (error) {
        return error;
      }
      fail('Expected a syntax error for "$source"');
    }

    test('examples', () {
      expect(errorFor('').toString(), 'formula is empty at position 1');
      expect(
        errorFor('max(1, 2').toString(),
        'expected ")" but found the end at position 9',
      );
      expect(errorFor('{points').position, 1);
      expect(errorFor('3 + ').toString(), 'formula ends too early at position 5');
      expect(errorFor('3 ^ 2').toString(), 'unexpected character "^" at position 3');
      expect(errorFor('1 < 2 < 3').message, 'comparisons cannot be chained; use "and"');
      expect(errorFor('4 5').toString(), 'unexpected "5" at position 3');
    });
  });

  group('checker', () {
    List<String> problemsFor(String source, {Set<String>? dependencies}) {
      return checkFormula(
        Formula.parse(source),
        lineIds: const {'points', 'bonus'},
        dependencies: dependencies,
      ).map((problem) => problem.toString()).toList();
    }

    test('a good formula has no problems and reports what it reads', () {
      final reads = <String>{};
      expect(
        problemsFor(
          'max(0, {points} - highestOther(bonus)) + {playerCount}',
          dependencies: reads,
        ),
        isEmpty,
      );
      expect(reads, {'points', 'bonus'});
    });

    test('unknown names and functions', () {
      expect(
        problemsFor('{score} + 1'),
        ['unknown name "score"; expected one of: points, bonus, playerCount, roundNumber, playerPosition at position 1'],
      );
      expect(
        problemsFor('double({points})').single,
        startsWith('unknown function "double"'),
      );
    });

    test('argument counts', () {
      expect(
        problemsFor('abs(1, 2)'),
        ['abs takes 1 argument, not 2 at position 1'],
      );
      expect(
        problemsFor('if(1, 2)'),
        ['if takes 3 arguments, not 2 at position 1'],
      );
      expect(
        problemsFor('max()'),
        ['max takes at least 1 argument, not 0 at position 1'],
      );
    });

    test('line names and braces are used in the right places', () {
      expect(problemsFor('points + 1'), ['use {points} to read a value at position 1']);
      expect(
        problemsFor('highestOther({points})'),
        [
          'highestOther needs a line name without braces, for example '
              'highestOther(points) at position 14',
        ],
      );
      expect(
        problemsFor('highestOther(score)'),
        ['unknown line "score" at position 14'],
      );
    });
  });
}
