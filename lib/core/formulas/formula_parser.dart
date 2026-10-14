/// Parses template formula strings such as
/// `max(0, {inning-points} - highestOther(inning-points))`.
///
/// See `_specs/template_schema.md` for the language.
library;

/// A formula that has been parsed but not yet checked against a template.
class Formula {
  Formula._(this.source, this.root);

  /// Parses [source], or throws [FormulaSyntaxError].
  factory Formula.parse(String source) {
    final parser = _Parser(source, _tokenize(source));
    final root = parser.parseFormula();
    return Formula._(source, root);
  }

  final String source;
  final FormulaNode root;
}

class FormulaSyntaxError implements Exception {
  const FormulaSyntaxError(this.message, this.position);

  final String message;

  /// 1-based character position in the formula.
  final int position;

  @override
  String toString() => '$message at position $position';
}

/// A node in a parsed formula. [position] is 1-based.
sealed class FormulaNode {
  const FormulaNode(this.position);

  final int position;
}

class NumberNode extends FormulaNode {
  const NumberNode(this.value, super.position);

  final int value;
}

/// `{name}`: one of this player's lines, or a built-in value.
class ReferenceNode extends FormulaNode {
  const ReferenceNode(this.name, super.position);

  final String name;
}

/// A bare name, only valid as the argument of an other-player function.
class FieldNameNode extends FormulaNode {
  const FieldNameNode(this.name, super.position);

  final String name;
}

class UnaryNode extends FormulaNode {
  const UnaryNode(this.operator, this.operand, super.position);

  /// `-` or `not`.
  final String operator;
  final FormulaNode operand;
}

class BinaryNode extends FormulaNode {
  const BinaryNode(this.operator, this.left, this.right, super.position);

  /// `+ - * / > >= < <= == != and or`.
  final String operator;
  final FormulaNode left;
  final FormulaNode right;
}

class CallNode extends FormulaNode {
  const CallNode(this.name, this.arguments, super.position);

  final String name;
  final List<FormulaNode> arguments;
}

enum _TokenKind { number, reference, name, symbol, end }

class _Token {
  const _Token(this.kind, this.text, this.position);

  final _TokenKind kind;
  final String text;
  final int position;

  @override
  String toString() => kind == _TokenKind.end ? 'the end' : '"$text"';
}

final _namePattern = RegExp(r'[A-Za-z][A-Za-z0-9]*(?:-[A-Za-z0-9]+)*');
final _numberPattern = RegExp(r'[0-9]+');
const _symbols = ['>=', '<=', '==', '!=', '+', '-', '*', '/', '%', '(', ')', ',', '>', '<'];

List<_Token> _tokenize(String source) {
  final tokens = <_Token>[];
  var index = 0;

  while (index < source.length) {
    final char = source[index];
    final position = index + 1;

    if (char.trim().isEmpty) {
      index += 1;
      continue;
    }

    final number = _numberPattern.matchAsPrefix(source, index);
    if (number != null) {
      tokens.add(_Token(_TokenKind.number, number[0]!, position));
      index = number.end;
      continue;
    }

    if (char == '{') {
      final name = _namePattern.matchAsPrefix(source, index + 1);
      if (name == null || name.end >= source.length || source[name.end] != '}') {
        throw FormulaSyntaxError(
          'expected a name and "}" after "{"',
          position,
        );
      }
      tokens.add(_Token(_TokenKind.reference, name[0]!, position));
      index = name.end + 1;
      continue;
    }

    final name = _namePattern.matchAsPrefix(source, index);
    if (name != null) {
      tokens.add(_Token(_TokenKind.name, name[0]!, position));
      index = name.end;
      continue;
    }

    final symbol = _symbols.where((s) => source.startsWith(s, index)).firstOrNull;
    if (symbol != null) {
      tokens.add(_Token(_TokenKind.symbol, symbol, position));
      index += symbol.length;
      continue;
    }

    throw FormulaSyntaxError('unexpected character "$char"', position);
  }

  tokens.add(_Token(_TokenKind.end, '', source.length + 1));
  return tokens;
}

/// Recursive descent, lowest precedence first:
/// or, and, not, comparison, + -, * /, unary -, value.
class _Parser {
  _Parser(this._source, this._tokens);

  final String _source;
  final List<_Token> _tokens;
  int _index = 0;

  _Token get _current => _tokens[_index];

  FormulaNode parseFormula() {
    if (_source.trim().isEmpty) {
      throw const FormulaSyntaxError('formula is empty', 1);
    }
    final node = _parseOr();
    if (_current.kind != _TokenKind.end) {
      throw FormulaSyntaxError('unexpected $_current', _current.position);
    }
    return node;
  }

  bool _isSymbol(String text) =>
      _current.kind == _TokenKind.symbol && _current.text == text;

  bool _isKeyword(String text) =>
      _current.kind == _TokenKind.name && _current.text == text;

  _Token _advance() => _tokens[_index++];

  void _expectSymbol(String text) {
    if (!_isSymbol(text)) {
      throw FormulaSyntaxError(
        'expected "$text" but found $_current',
        _current.position,
      );
    }
    _advance();
  }

  FormulaNode _parseOr() {
    var left = _parseAnd();
    while (_isKeyword('or')) {
      final token = _advance();
      left = BinaryNode('or', left, _parseAnd(), token.position);
    }
    return left;
  }

  FormulaNode _parseAnd() {
    var left = _parseNot();
    while (_isKeyword('and')) {
      final token = _advance();
      left = BinaryNode('and', left, _parseNot(), token.position);
    }
    return left;
  }

  FormulaNode _parseNot() {
    if (_isKeyword('not')) {
      final token = _advance();
      return UnaryNode('not', _parseNot(), token.position);
    }
    return _parseComparison();
  }

  FormulaNode _parseComparison() {
    final left = _parseAdditive();
    const comparisons = {'>', '>=', '<', '<=', '==', '!='};
    if (_current.kind == _TokenKind.symbol &&
        comparisons.contains(_current.text)) {
      final token = _advance();
      final node = BinaryNode(token.text, left, _parseAdditive(), token.position);
      if (_current.kind == _TokenKind.symbol &&
          comparisons.contains(_current.text)) {
        throw FormulaSyntaxError(
          'comparisons cannot be chained; use "and"',
          _current.position,
        );
      }
      return node;
    }
    return left;
  }

  FormulaNode _parseAdditive() {
    var left = _parseMultiplicative();
    while (_isSymbol('+') || _isSymbol('-')) {
      final token = _advance();
      left = BinaryNode(token.text, left, _parseMultiplicative(), token.position);
    }
    return left;
  }

  FormulaNode _parseMultiplicative() {
    var left = _parseUnary();
    while (_isSymbol('*') || _isSymbol('/') || _isSymbol('%')) {
      final token = _advance();
      left = BinaryNode(token.text, left, _parseUnary(), token.position);
    }
    return left;
  }

  FormulaNode _parseUnary() {
    if (_isSymbol('-')) {
      final token = _advance();
      return UnaryNode('-', _parseUnary(), token.position);
    }
    return _parseValue();
  }

  FormulaNode _parseValue() {
    final token = _current;
    switch (token.kind) {
      case _TokenKind.number:
        _advance();
        return NumberNode(int.parse(token.text), token.position);
      case _TokenKind.reference:
        _advance();
        return ReferenceNode(token.text, token.position);
      case _TokenKind.name:
        _advance();
        if (_isSymbol('(')) {
          return _parseCall(token);
        }
        return FieldNameNode(token.text, token.position);
      case _TokenKind.symbol:
        if (token.text == '(') {
          _advance();
          final inner = _parseOr();
          _expectSymbol(')');
          return inner;
        }
        throw FormulaSyntaxError('unexpected $token', token.position);
      case _TokenKind.end:
        throw FormulaSyntaxError('formula ends too early', token.position);
    }
  }

  FormulaNode _parseCall(_Token name) {
    _expectSymbol('(');
    final arguments = <FormulaNode>[];
    if (!_isSymbol(')')) {
      arguments.add(_parseOr());
      while (_isSymbol(',')) {
        _advance();
        arguments.add(_parseOr());
      }
    }
    _expectSymbol(')');
    return CallNode(name.text, arguments, name.position);
  }
}
