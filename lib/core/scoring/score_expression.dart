enum ScoreOperator {
  add('+'),
  subtract('−'),
  multiply('×'),
  divide('÷');

  const ScoreOperator(this.symbol);

  final String symbol;
}

/// A calculator-style score entry such as `3 + 4 + 5 × 2`.
///
/// Evaluates strictly left to right like a running tally, so the example is
/// 24 rather than 17. Division rounds down to a whole number.
class ScoreExpression {
  const ScoreExpression() : _terms = const [];

  const ScoreExpression._(this._terms);

  /// Alternating numbers and operators, starting with a number. The last term
  /// may be an operator or a number still being typed.
  final List<_Term> _terms;

  bool get isEmpty => _terms.isEmpty;

  bool get hasOperator => _terms.any((term) => term is _OperatorTerm);

  ScoreExpression appendDigit(String digit) {
    final last = _lastNumber;
    if (last == null) {
      return _push(_NumberTerm(digits: digit));
    }

    final digits = last.digits == '0' ? digit : last.digits + digit;
    return _replaceLast(_NumberTerm(digits: digits, isNegative: last.isNegative));
  }

  /// Flips the sign of the number being typed, starting one if needed.
  ScoreExpression toggleSign() {
    final last = _lastNumber;
    if (last == null) {
      return _push(const _NumberTerm(digits: '', isNegative: true));
    }

    return _replaceLast(
      _NumberTerm(digits: last.digits, isNegative: !last.isNegative),
    );
  }

  /// Adds an operator. Does nothing before the first number, and replaces an
  /// operator that was just pressed.
  ScoreExpression applyOperator(ScoreOperator operator) {
    if (_terms.isEmpty) {
      return this;
    }

    final last = _terms.last;
    if (last is _OperatorTerm) {
      return _replaceLast(_OperatorTerm(operator));
    }

    if (last is _NumberTerm && last.digits.isEmpty) {
      return this;
    }

    return _push(_OperatorTerm(operator));
  }

  ScoreExpression backspace() {
    if (_terms.isEmpty) {
      return this;
    }

    final last = _terms.last;
    if (last is _NumberTerm && last.digits.length > 1) {
      return _replaceLast(
        _NumberTerm(
          digits: last.digits.substring(0, last.digits.length - 1),
          isNegative: last.isNegative,
        ),
      );
    }

    if (last is _NumberTerm && last.digits.length == 1 && last.isNegative) {
      return _replaceLast(const _NumberTerm(digits: '', isNegative: true));
    }

    return ScoreExpression._(_terms.sublist(0, _terms.length - 1));
  }

  /// The running result, ignoring a trailing operator or an unfinished
  /// number. Null when nothing has been entered or on division by zero.
  int? get value => _evaluate().value;

  bool get dividesByZero => _evaluate().dividesByZero;

  /// The entry as typed, for example `3 + 4 × (-2)`.
  String get displayText {
    if (_terms.isEmpty) {
      return '0';
    }

    final parts = <String>[];
    for (var index = 0; index < _terms.length; index++) {
      final term = _terms[index];
      parts.add(switch (term) {
        _OperatorTerm(:final operator) => operator.symbol,
        _NumberTerm() => index > 0 && term.isNegative
            ? '(${term.displayText})'
            : term.displayText,
      });
    }

    return parts.join(' ');
  }

  _NumberTerm? get _lastNumber {
    if (_terms.isEmpty) {
      return null;
    }

    final last = _terms.last;
    return last is _NumberTerm ? last : null;
  }

  ScoreExpression _push(_Term term) => ScoreExpression._([..._terms, term]);

  ScoreExpression _replaceLast(_Term term) =>
      ScoreExpression._([..._terms.sublist(0, _terms.length - 1), term]);

  ({int? value, bool dividesByZero}) _evaluate() {
    int? result;
    ScoreOperator? pendingOperator;

    for (final term in _terms) {
      switch (term) {
        case _OperatorTerm(:final operator):
          pendingOperator = operator;
        case _NumberTerm():
          final number = term.value;
          if (number == null) {
            continue;
          }

          if (result == null || pendingOperator == null) {
            result = number;
            continue;
          }

          if (pendingOperator == ScoreOperator.divide && number == 0) {
            return (value: null, dividesByZero: true);
          }

          result = _apply(result, pendingOperator, number);
      }
    }

    return (value: result, dividesByZero: false);
  }
}

int _apply(int left, ScoreOperator operator, int right) {
  return switch (operator) {
    ScoreOperator.add => left + right,
    ScoreOperator.subtract => left - right,
    ScoreOperator.multiply => left * right,
    ScoreOperator.divide => _divideRoundingDown(left, right),
  };
}

int _divideRoundingDown(int left, int right) {
  final quotient = left ~/ right;
  final hasRemainder = quotient * right != left;
  final isNegative = (left < 0) != (right < 0);
  return hasRemainder && isNegative ? quotient - 1 : quotient;
}

sealed class _Term {
  const _Term();
}

class _NumberTerm extends _Term {
  const _NumberTerm({required this.digits, this.isNegative = false});

  final String digits;
  final bool isNegative;

  int? get value {
    if (digits.isEmpty) {
      return null;
    }

    final magnitude = int.parse(digits);
    return isNegative ? -magnitude : magnitude;
  }

  String get displayText => '${isNegative ? '-' : ''}${digits.isEmpty ? '' : digits}';
}

class _OperatorTerm extends _Term {
  const _OperatorTerm(this.operator);

  final ScoreOperator operator;
}
