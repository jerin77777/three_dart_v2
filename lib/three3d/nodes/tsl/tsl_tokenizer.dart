/// TSL (Three Shading Language) Tokenizer
/// 
/// Tokenizes TSL syntax into a stream of tokens for parsing.
/// TSL is a simplified shading language that compiles to node graphs.

/// Token types in TSL
enum TokenType {
  // Literals
  number,
  string,
  identifier,
  
  // Keywords
  keywordFn,
  keywordVar,
  keywordConst,
  keywordReturn,
  keywordIf,
  keywordElse,
  keywordFor,
  keywordWhile,
  
  // Types
  typeFloat,
  typeInt,
  typeVec2,
  typeVec3,
  typeVec4,
  typeMat2,
  typeMat3,
  typeMat4,
  typeSampler2D,
  typeSamplerCube,
  
  // Operators
  plus,
  minus,
  multiply,
  divide,
  modulo,
  assign,
  equal,
  notEqual,
  lessThan,
  lessThanEqual,
  greaterThan,
  greaterThanEqual,
  and,
  or,
  not,
  
  // Delimiters
  leftParen,
  rightParen,
  leftBrace,
  rightBrace,
  leftBracket,
  rightBracket,
  comma,
  semicolon,
  dot,
  colon,
  arrow,
  
  // Special
  eof,
  unknown,
}

/// A token in the TSL source code
class Token {
  final TokenType type;
  final String lexeme;
  final dynamic literal;
  final int line;
  final int column;
  
  Token({
    required this.type,
    required this.lexeme,
    this.literal,
    required this.line,
    required this.column,
  });
  
  @override
  String toString() {
    return 'Token($type, "$lexeme", line: $line, col: $column)';
  }
}

/// Tokenizes TSL source code into tokens
class TSLTokenizer {
  final String source;
  final List<Token> tokens = [];
  
  int _start = 0;
  int _current = 0;
  int _line = 1;
  int _column = 1;
  
  static final Map<String, TokenType> _keywords = {
    'fn': TokenType.keywordFn,
    'var': TokenType.keywordVar,
    'const': TokenType.keywordConst,
    'return': TokenType.keywordReturn,
    'if': TokenType.keywordIf,
    'else': TokenType.keywordElse,
    'for': TokenType.keywordFor,
    'while': TokenType.keywordWhile,
    'float': TokenType.typeFloat,
    'int': TokenType.typeInt,
    'vec2': TokenType.typeVec2,
    'vec3': TokenType.typeVec3,
    'vec4': TokenType.typeVec4,
    'mat2': TokenType.typeMat2,
    'mat3': TokenType.typeMat3,
    'mat4': TokenType.typeMat4,
    'sampler2D': TokenType.typeSampler2D,
    'samplerCube': TokenType.typeSamplerCube,
  };
  
  TSLTokenizer(this.source);
  
  /// Tokenize the source code
  List<Token> tokenize() {
    while (!_isAtEnd()) {
      _start = _current;
      _scanToken();
    }
    
    tokens.add(Token(
      type: TokenType.eof,
      lexeme: '',
      line: _line,
      column: _column,
    ));
    
    return tokens;
  }
  
  void _scanToken() {
    String c = _advance();
    
    switch (c) {
      // Single character tokens
      case '(':
        _addToken(TokenType.leftParen);
        break;
      case ')':
        _addToken(TokenType.rightParen);
        break;
      case '{':
        _addToken(TokenType.leftBrace);
        break;
      case '}':
        _addToken(TokenType.rightBrace);
        break;
      case '[':
        _addToken(TokenType.leftBracket);
        break;
      case ']':
        _addToken(TokenType.rightBracket);
        break;
      case ',':
        _addToken(TokenType.comma);
        break;
      case ';':
        _addToken(TokenType.semicolon);
        break;
      case '.':
        _addToken(TokenType.dot);
        break;
      case ':':
        _addToken(TokenType.colon);
        break;
      case '+':
        _addToken(TokenType.plus);
        break;
      case '*':
        _addToken(TokenType.multiply);
        break;
      case '%':
        _addToken(TokenType.modulo);
        break;
      
      // Two character tokens
      case '-':
        if (_match('>')) {
          _addToken(TokenType.arrow);
        } else {
          _addToken(TokenType.minus);
        }
        break;
      case '/':
        if (_match('/')) {
          // Single line comment
          while (_peek() != '\n' && !_isAtEnd()) {
            _advance();
          }
        } else if (_match('*')) {
          // Multi-line comment
          _blockComment();
        } else {
          _addToken(TokenType.divide);
        }
        break;
      case '=':
        _addToken(_match('=') ? TokenType.equal : TokenType.assign);
        break;
      case '!':
        _addToken(_match('=') ? TokenType.notEqual : TokenType.not);
        break;
      case '<':
        _addToken(_match('=') ? TokenType.lessThanEqual : TokenType.lessThan);
        break;
      case '>':
        _addToken(_match('=') ? TokenType.greaterThanEqual : TokenType.greaterThan);
        break;
      case '&':
        if (_match('&')) {
          _addToken(TokenType.and);
        }
        break;
      case '|':
        if (_match('|')) {
          _addToken(TokenType.or);
        }
        break;
      
      // Whitespace
      case ' ':
      case '\r':
      case '\t':
        // Ignore whitespace
        break;
      case '\n':
        _line++;
        _column = 1;
        break;
      
      // String literals
      case '"':
      case "'":
        _string(c);
        break;
      
      default:
        if (_isDigit(c)) {
          _number();
        } else if (_isAlpha(c)) {
          _identifier();
        } else {
          _addToken(TokenType.unknown);
        }
        break;
    }
  }
  
  void _blockComment() {
    while (!_isAtEnd()) {
      if (_peek() == '*' && _peekNext() == '/') {
        _advance(); // consume *
        _advance(); // consume /
        break;
      }
      if (_peek() == '\n') {
        _line++;
        _column = 1;
      }
      _advance();
    }
  }
  
  void _string(String quote) {
    while (_peek() != quote && !_isAtEnd()) {
      if (_peek() == '\n') {
        _line++;
        _column = 1;
      }
      _advance();
    }
    
    if (_isAtEnd()) {
      // Unterminated string
      _addToken(TokenType.unknown);
      return;
    }
    
    // Consume closing quote
    _advance();
    
    // Extract string value (without quotes)
    String value = source.substring(_start + 1, _current - 1);
    _addToken(TokenType.string, literal: value);
  }
  
  void _number() {
    while (_isDigit(_peek())) {
      _advance();
    }
    
    // Look for decimal part
    if (_peek() == '.' && _isDigit(_peekNext())) {
      // Consume the '.'
      _advance();
      
      while (_isDigit(_peek())) {
        _advance();
      }
    }
    
    // Look for exponent
    if (_peek() == 'e' || _peek() == 'E') {
      _advance();
      if (_peek() == '+' || _peek() == '-') {
        _advance();
      }
      while (_isDigit(_peek())) {
        _advance();
      }
    }
    
    String value = source.substring(_start, _current);
    _addToken(TokenType.number, literal: double.parse(value));
  }
  
  void _identifier() {
    while (_isAlphaNumeric(_peek())) {
      _advance();
    }
    
    String text = source.substring(_start, _current);
    TokenType type = _keywords[text] ?? TokenType.identifier;
    _addToken(type);
  }
  
  bool _match(String expected) {
    if (_isAtEnd()) return false;
    if (source[_current] != expected) return false;
    
    _current++;
    _column++;
    return true;
  }
  
  String _peek() {
    if (_isAtEnd()) return '\0';
    return source[_current];
  }
  
  String _peekNext() {
    if (_current + 1 >= source.length) return '\0';
    return source[_current + 1];
  }
  
  bool _isDigit(String c) {
    return c.codeUnitAt(0) >= '0'.codeUnitAt(0) && 
           c.codeUnitAt(0) <= '9'.codeUnitAt(0);
  }
  
  bool _isAlpha(String c) {
    int code = c.codeUnitAt(0);
    return (code >= 'a'.codeUnitAt(0) && code <= 'z'.codeUnitAt(0)) ||
           (code >= 'A'.codeUnitAt(0) && code <= 'Z'.codeUnitAt(0)) ||
           c == '_';
  }
  
  bool _isAlphaNumeric(String c) {
    return _isAlpha(c) || _isDigit(c);
  }
  
  String _advance() {
    _column++;
    return source[_current++];
  }
  
  void _addToken(TokenType type, {dynamic literal}) {
    String text = source.substring(_start, _current);
    tokens.add(Token(
      type: type,
      lexeme: text,
      literal: literal,
      line: _line,
      column: _column - text.length,
    ));
  }
  
  bool _isAtEnd() {
    return _current >= source.length;
  }
}
