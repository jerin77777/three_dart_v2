/// GLSL (OpenGL Shading Language) Tokenizer
/// 
/// Tokenizes GLSL source code into a stream of tokens for parsing.
/// Supports GLSL ES 3.0 and GLSL 3.3 syntax.

/// Token types in GLSL
enum GLSLTokenType {
  // Literals
  intLiteral,
  floatLiteral,
  boolLiteral,
  
  // Identifiers
  identifier,
  
  // Keywords
  keywordAttribute,
  keywordConst,
  keywordUniform,
  keywordVarying,
  keywordBreak,
  keywordContinue,
  keywordDo,
  keywordFor,
  keywordWhile,
  keywordIf,
  keywordElse,
  keywordIn,
  keywordOut,
  keywordInout,
  keywordReturn,
  keywordDiscard,
  keywordStruct,
  keywordVoid,
  keywordLayout,
  keywordPrecision,
  keywordHighp,
  keywordMediump,
  keywordLowp,
  
  // Types
  typeBool,
  typeInt,
  typeUint,
  typeFloat,
  typeDouble,
  typeVec2,
  typeVec3,
  typeVec4,
  typeIvec2,
  typeIvec3,
  typeIvec4,
  typeUvec2,
  typeUvec3,
  typeUvec4,
  typeBvec2,
  typeBvec3,
  typeBvec4,
  typeMat2,
  typeMat3,
  typeMat4,
  typeMat2x2,
  typeMat2x3,
  typeMat2x4,
  typeMat3x2,
  typeMat3x3,
  typeMat3x4,
  typeMat4x2,
  typeMat4x3,
  typeMat4x4,
  typeSampler2D,
  typeSampler3D,
  typeSamplerCube,
  typeSampler2DShadow,
  typeSamplerCubeShadow,
  typeSampler2DArray,
  typeSampler2DArrayShadow,
  typeIsampler2D,
  typeIsampler3D,
  typeIsamplerCube,
  typeIsampler2DArray,
  typeUsampler2D,
  typeUsampler3D,
  typeUsamplerCube,
  typeUsampler2DArray,
  
  // Operators
  plus,
  minus,
  multiply,
  divide,
  modulo,
  assign,
  plusAssign,
  minusAssign,
  multiplyAssign,
  divideAssign,
  moduloAssign,
  equal,
  notEqual,
  lessThan,
  lessThanEqual,
  greaterThan,
  greaterThanEqual,
  and,
  or,
  xor,
  not,
  bitwiseAnd,
  bitwiseOr,
  bitwiseXor,
  bitwiseNot,
  leftShift,
  rightShift,
  increment,
  decrement,
  ternary,
  
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
  
  // Preprocessor
  preprocessor,
  
  // Special
  eof,
  unknown,
}

/// A token in the GLSL source code
class GLSLToken {
  final GLSLTokenType type;
  final String lexeme;
  final dynamic literal;
  final int line;
  final int column;
  
  GLSLToken({
    required this.type,
    required this.lexeme,
    this.literal,
    required this.line,
    required this.column,
  });
  
  @override
  String toString() {
    return 'GLSLToken($type, "$lexeme", line: $line, col: $column)';
  }
}

/// Tokenizes GLSL source code into tokens
class GLSLTokenizer {
  final String source;
  final List<GLSLToken> tokens = [];
  
  int _start = 0;
  int _current = 0;
  int _line = 1;
  int _column = 1;
  
  static final Map<String, GLSLTokenType> _keywords = {
    // Keywords
    'attribute': GLSLTokenType.keywordAttribute,
    'const': GLSLTokenType.keywordConst,
    'uniform': GLSLTokenType.keywordUniform,
    'varying': GLSLTokenType.keywordVarying,
    'break': GLSLTokenType.keywordBreak,
    'continue': GLSLTokenType.keywordContinue,
    'do': GLSLTokenType.keywordDo,
    'for': GLSLTokenType.keywordFor,
    'while': GLSLTokenType.keywordWhile,
    'if': GLSLTokenType.keywordIf,
    'else': GLSLTokenType.keywordElse,
    'in': GLSLTokenType.keywordIn,
    'out': GLSLTokenType.keywordOut,
    'inout': GLSLTokenType.keywordInout,
    'return': GLSLTokenType.keywordReturn,
    'discard': GLSLTokenType.keywordDiscard,
    'struct': GLSLTokenType.keywordStruct,
    'void': GLSLTokenType.keywordVoid,
    'layout': GLSLTokenType.keywordLayout,
    'precision': GLSLTokenType.keywordPrecision,
    'highp': GLSLTokenType.keywordHighp,
    'mediump': GLSLTokenType.keywordMediump,
    'lowp': GLSLTokenType.keywordLowp,
    
    // Boolean literals
    'true': GLSLTokenType.boolLiteral,
    'false': GLSLTokenType.boolLiteral,
    
    // Types
    'bool': GLSLTokenType.typeBool,
    'int': GLSLTokenType.typeInt,
    'uint': GLSLTokenType.typeUint,
    'float': GLSLTokenType.typeFloat,
    'double': GLSLTokenType.typeDouble,
    'vec2': GLSLTokenType.typeVec2,
    'vec3': GLSLTokenType.typeVec3,
    'vec4': GLSLTokenType.typeVec4,
    'ivec2': GLSLTokenType.typeIvec2,
    'ivec3': GLSLTokenType.typeIvec3,
    'ivec4': GLSLTokenType.typeIvec4,
    'uvec2': GLSLTokenType.typeUvec2,
    'uvec3': GLSLTokenType.typeUvec3,
    'uvec4': GLSLTokenType.typeUvec4,
    'bvec2': GLSLTokenType.typeBvec2,
    'bvec3': GLSLTokenType.typeBvec3,
    'bvec4': GLSLTokenType.typeBvec4,
    'mat2': GLSLTokenType.typeMat2,
    'mat3': GLSLTokenType.typeMat3,
    'mat4': GLSLTokenType.typeMat4,
    'mat2x2': GLSLTokenType.typeMat2x2,
    'mat2x3': GLSLTokenType.typeMat2x3,
    'mat2x4': GLSLTokenType.typeMat2x4,
    'mat3x2': GLSLTokenType.typeMat3x2,
    'mat3x3': GLSLTokenType.typeMat3x3,
    'mat3x4': GLSLTokenType.typeMat3x4,
    'mat4x2': GLSLTokenType.typeMat4x2,
    'mat4x3': GLSLTokenType.typeMat4x3,
    'mat4x4': GLSLTokenType.typeMat4x4,
    'sampler2D': GLSLTokenType.typeSampler2D,
    'sampler3D': GLSLTokenType.typeSampler3D,
    'samplerCube': GLSLTokenType.typeSamplerCube,
    'sampler2DShadow': GLSLTokenType.typeSampler2DShadow,
    'samplerCubeShadow': GLSLTokenType.typeSamplerCubeShadow,
    'sampler2DArray': GLSLTokenType.typeSampler2DArray,
    'sampler2DArrayShadow': GLSLTokenType.typeSampler2DArrayShadow,
    'isampler2D': GLSLTokenType.typeIsampler2D,
    'isampler3D': GLSLTokenType.typeIsampler3D,
    'isamplerCube': GLSLTokenType.typeIsamplerCube,
    'isampler2DArray': GLSLTokenType.typeIsampler2DArray,
    'usampler2D': GLSLTokenType.typeUsampler2D,
    'usampler3D': GLSLTokenType.typeUsampler3D,
    'usamplerCube': GLSLTokenType.typeUsamplerCube,
    'usampler2DArray': GLSLTokenType.typeUsampler2DArray,
  };
  
  GLSLTokenizer(this.source);
  
  /// Tokenize the source code
  List<GLSLToken> tokenize() {
    while (!_isAtEnd()) {
      _start = _current;
      _scanToken();
    }
    
    tokens.add(GLSLToken(
      type: GLSLTokenType.eof,
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
        _addToken(GLSLTokenType.leftParen);
        break;
      case ')':
        _addToken(GLSLTokenType.rightParen);
        break;
      case '{':
        _addToken(GLSLTokenType.leftBrace);
        break;
      case '}':
        _addToken(GLSLTokenType.rightBrace);
        break;
      case '[':
        _addToken(GLSLTokenType.leftBracket);
        break;
      case ']':
        _addToken(GLSLTokenType.rightBracket);
        break;
      case ',':
        _addToken(GLSLTokenType.comma);
        break;
      case ';':
        _addToken(GLSLTokenType.semicolon);
        break;
      case '.':
        // Check for number starting with .
        if (_isDigit(_peek())) {
          _number();
        } else {
          _addToken(GLSLTokenType.dot);
        }
        break;
      case ':':
        _addToken(GLSLTokenType.colon);
        break;
      case '?':
        _addToken(GLSLTokenType.ternary);
        break;
      case '~':
        _addToken(GLSLTokenType.bitwiseNot);
        break;
      
      // Two or three character tokens
      case '+':
        if (_match('+')) {
          _addToken(GLSLTokenType.increment);
        } else if (_match('=')) {
          _addToken(GLSLTokenType.plusAssign);
        } else {
          _addToken(GLSLTokenType.plus);
        }
        break;
      case '-':
        if (_match('-')) {
          _addToken(GLSLTokenType.decrement);
        } else if (_match('=')) {
          _addToken(GLSLTokenType.minusAssign);
        } else {
          _addToken(GLSLTokenType.minus);
        }
        break;
      case '*':
        _addToken(_match('=') ? GLSLTokenType.multiplyAssign : GLSLTokenType.multiply);
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
        } else if (_match('=')) {
          _addToken(GLSLTokenType.divideAssign);
        } else {
          _addToken(GLSLTokenType.divide);
        }
        break;
      case '%':
        _addToken(_match('=') ? GLSLTokenType.moduloAssign : GLSLTokenType.modulo);
        break;
      case '=':
        _addToken(_match('=') ? GLSLTokenType.equal : GLSLTokenType.assign);
        break;
      case '!':
        _addToken(_match('=') ? GLSLTokenType.notEqual : GLSLTokenType.not);
        break;
      case '<':
        if (_match('<')) {
          _addToken(GLSLTokenType.leftShift);
        } else if (_match('=')) {
          _addToken(GLSLTokenType.lessThanEqual);
        } else {
          _addToken(GLSLTokenType.lessThan);
        }
        break;
      case '>':
        if (_match('>')) {
          _addToken(GLSLTokenType.rightShift);
        } else if (_match('=')) {
          _addToken(GLSLTokenType.greaterThanEqual);
        } else {
          _addToken(GLSLTokenType.greaterThan);
        }
        break;
      case '&':
        if (_match('&')) {
          _addToken(GLSLTokenType.and);
        } else {
          _addToken(GLSLTokenType.bitwiseAnd);
        }
        break;
      case '|':
        if (_match('|')) {
          _addToken(GLSLTokenType.or);
        } else {
          _addToken(GLSLTokenType.bitwiseOr);
        }
        break;
      case '^':
        if (_match('^')) {
          _addToken(GLSLTokenType.xor);
        } else {
          _addToken(GLSLTokenType.bitwiseXor);
        }
        break;
      
      // Preprocessor directives
      case '#':
        _preprocessor();
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
      
      default:
        if (_isDigit(c)) {
          _number();
        } else if (_isAlpha(c)) {
          _identifier();
        } else {
          _addToken(GLSLTokenType.unknown);
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
  
  void _preprocessor() {
    // Consume entire preprocessor line
    while (_peek() != '\n' && !_isAtEnd()) {
      _advance();
    }
    
    String text = source.substring(_start, _current);
    _addToken(GLSLTokenType.preprocessor, literal: text);
  }
  
  void _number() {
    // Handle numbers starting with .
    if (_start < _current && source[_start] == '.') {
      // Already consumed the dot, now get digits
      while (_isDigit(_peek())) {
        _advance();
      }
      
      // Check for exponent
      if (_peek() == 'e' || _peek() == 'E') {
        _advance();
        if (_peek() == '+' || _peek() == '-') {
          _advance();
        }
        while (_isDigit(_peek())) {
          _advance();
        }
      }
      
      // Check for float suffix
      if (_peek() == 'f' || _peek() == 'F') {
        _advance();
      }
      
      String value = source.substring(_start, _current);
      _addToken(GLSLTokenType.floatLiteral, literal: double.parse(value.replaceAll('f', '').replaceAll('F', '')));
      return;
    }
    
    // Regular number
    bool isFloat = false;
    
    while (_isDigit(_peek())) {
      _advance();
    }
    
    // Look for decimal part
    if (_peek() == '.' && _isDigit(_peekNext())) {
      isFloat = true;
      // Consume the '.'
      _advance();
      
      while (_isDigit(_peek())) {
        _advance();
      }
    }
    
    // Look for exponent
    if (_peek() == 'e' || _peek() == 'E') {
      isFloat = true;
      _advance();
      if (_peek() == '+' || _peek() == '-') {
        _advance();
      }
      while (_isDigit(_peek())) {
        _advance();
      }
    }
    
    // Check for suffixes
    String suffix = '';
    if (_peek() == 'f' || _peek() == 'F') {
      isFloat = true;
      suffix = _peek();
      _advance();
    } else if (_peek() == 'u' || _peek() == 'U') {
      suffix = _peek();
      _advance();
    }
    
    String value = source.substring(_start, _current);
    
    if (isFloat) {
      _addToken(GLSLTokenType.floatLiteral, 
        literal: double.parse(value.replaceAll('f', '').replaceAll('F', '')));
    } else if (suffix == 'u' || suffix == 'U') {
      _addToken(GLSLTokenType.intLiteral, 
        literal: int.parse(value.replaceAll('u', '').replaceAll('U', '')));
    } else {
      _addToken(GLSLTokenType.intLiteral, literal: int.parse(value));
    }
  }
  
  void _identifier() {
    while (_isAlphaNumeric(_peek())) {
      _advance();
    }
    
    String text = source.substring(_start, _current);
    GLSLTokenType type = _keywords[text] ?? GLSLTokenType.identifier;
    
    // Handle boolean literals
    if (type == GLSLTokenType.boolLiteral) {
      _addToken(type, literal: text == 'true');
    } else {
      _addToken(type);
    }
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
    if (c == '\0') return false;
    return c.codeUnitAt(0) >= '0'.codeUnitAt(0) && 
           c.codeUnitAt(0) <= '9'.codeUnitAt(0);
  }
  
  bool _isAlpha(String c) {
    if (c == '\0') return false;
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
  
  void _addToken(GLSLTokenType type, {dynamic literal}) {
    String text = source.substring(_start, _current);
    tokens.add(GLSLToken(
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
