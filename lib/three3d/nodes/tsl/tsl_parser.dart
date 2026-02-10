/// TSL (Three Shading Language) Parser
/// 
/// Parses TSL tokens into an Abstract Syntax Tree (AST).
/// The AST can then be converted to a node graph.

import 'tsl_tokenizer.dart';

/// Base class for all AST nodes
abstract class ASTNode {
  int get line;
  int get column;
}

/// Program node - root of the AST
class ProgramNode extends ASTNode {
  final List<StatementNode> statements;
  
  @override
  final int line;
  
  @override
  final int column;
  
  ProgramNode(this.statements, {required this.line, required this.column});
}

/// Base class for statements
abstract class StatementNode extends ASTNode {}

/// Function declaration statement
class FunctionDeclNode extends StatementNode {
  final String name;
  final List<ParameterNode> parameters;
  final String returnType;
  final BlockNode body;
  
  @override
  final int line;
  
  @override
  final int column;
  
  FunctionDeclNode({
    required this.name,
    required this.parameters,
    required this.returnType,
    required this.body,
    required this.line,
    required this.column,
  });
}

/// Function parameter
class ParameterNode {
  final String name;
  final String type;
  final int line;
  final int column;
  
  ParameterNode({
    required this.name,
    required this.type,
    required this.line,
    required this.column,
  });
}

/// Variable declaration statement
class VarDeclNode extends StatementNode {
  final String name;
  final String? type;
  final ExpressionNode? initializer;
  final bool isConst;
  
  @override
  final int line;
  
  @override
  final int column;
  
  VarDeclNode({
    required this.name,
    this.type,
    this.initializer,
    this.isConst = false,
    required this.line,
    required this.column,
  });
}

/// Return statement
class ReturnNode extends StatementNode {
  final ExpressionNode? value;
  
  @override
  final int line;
  
  @override
  final int column;
  
  ReturnNode(this.value, {required this.line, required this.column});
}

/// Expression statement
class ExpressionStatementNode extends StatementNode {
  final ExpressionNode expression;
  
  @override
  final int line;
  
  @override
  final int column;
  
  ExpressionStatementNode(this.expression, {required this.line, required this.column});
}

/// Block statement
class BlockNode extends StatementNode {
  final List<StatementNode> statements;
  
  @override
  final int line;
  
  @override
  final int column;
  
  BlockNode(this.statements, {required this.line, required this.column});
}

/// If statement
class IfNode extends StatementNode {
  final ExpressionNode condition;
  final StatementNode thenBranch;
  final StatementNode? elseBranch;
  
  @override
  final int line;
  
  @override
  final int column;
  
  IfNode({
    required this.condition,
    required this.thenBranch,
    this.elseBranch,
    required this.line,
    required this.column,
  });
}

/// Base class for expressions
abstract class ExpressionNode extends ASTNode {}

/// Binary expression (e.g., a + b)
class BinaryNode extends ExpressionNode {
  final ExpressionNode left;
  final TokenType operator;
  final ExpressionNode right;
  
  @override
  final int line;
  
  @override
  final int column;
  
  BinaryNode({
    required this.left,
    required this.operator,
    required this.right,
    required this.line,
    required this.column,
  });
}

/// Unary expression (e.g., -a, !b)
class UnaryNode extends ExpressionNode {
  final TokenType operator;
  final ExpressionNode operand;
  
  @override
  final int line;
  
  @override
  final int column;
  
  UnaryNode({
    required this.operator,
    required this.operand,
    required this.line,
    required this.column,
  });
}

/// Function call expression
class CallNode extends ExpressionNode {
  final ExpressionNode callee;
  final List<ExpressionNode> arguments;
  
  @override
  final int line;
  
  @override
  final int column;
  
  CallNode({
    required this.callee,
    required this.arguments,
    required this.line,
    required this.column,
  });
}

/// Member access expression (e.g., vec.x)
class MemberNode extends ExpressionNode {
  final ExpressionNode object;
  final String member;
  
  @override
  final int line;
  
  @override
  final int column;
  
  MemberNode({
    required this.object,
    required this.member,
    required this.line,
    required this.column,
  });
}

/// Identifier expression
class IdentifierNode extends ExpressionNode {
  final String name;
  
  @override
  final int line;
  
  @override
  final int column;
  
  IdentifierNode(this.name, {required this.line, required this.column});
}

/// Literal expression (number, string)
class LiteralNode extends ExpressionNode {
  final dynamic value;
  
  @override
  final int line;
  
  @override
  final int column;
  
  LiteralNode(this.value, {required this.line, required this.column});
}

/// Assignment expression
class AssignmentNode extends ExpressionNode {
  final String name;
  final ExpressionNode value;
  
  @override
  final int line;
  
  @override
  final int column;
  
  AssignmentNode({
    required this.name,
    required this.value,
    required this.line,
    required this.column,
  });
}

/// Parse error exception
class TSLParseError implements Exception {
  final String message;
  final int line;
  final int column;
  
  TSLParseError(this.message, {required this.line, required this.column});
  
  @override
  String toString() => 'TSL Parse Error at line $line, column $column: $message';
}

/// TSL Parser - converts tokens to AST
class TSLParser {
  final List<Token> tokens;
  int _current = 0;
  
  TSLParser(this.tokens);
  
  /// Parse the tokens into an AST
  ProgramNode parse() {
    List<StatementNode> statements = [];
    
    while (!_isAtEnd()) {
      try {
        statements.add(_declaration());
      } catch (e) {
        if (e is TSLParseError) {
          rethrow;
        }
        // Synchronize on error
        _synchronize();
      }
    }
    
    return ProgramNode(statements, line: 1, column: 1);
  }
  
  StatementNode _declaration() {
    if (_match([TokenType.keywordFn])) {
      return _functionDeclaration();
    }
    if (_match([TokenType.keywordVar, TokenType.keywordConst])) {
      return _varDeclaration();
    }
    
    return _statement();
  }
  
  FunctionDeclNode _functionDeclaration() {
    Token nameToken = _consume(TokenType.identifier, 'Expected function name');
    
    _consume(TokenType.leftParen, 'Expected "(" after function name');
    
    List<ParameterNode> parameters = [];
    if (!_check(TokenType.rightParen)) {
      do {
        Token typeToken = _consumeType('Expected parameter type');
        Token paramName = _consume(TokenType.identifier, 'Expected parameter name');
        
        parameters.add(ParameterNode(
          name: paramName.lexeme,
          type: typeToken.lexeme,
          line: paramName.line,
          column: paramName.column,
        ));
      } while (_match([TokenType.comma]));
    }
    
    _consume(TokenType.rightParen, 'Expected ")" after parameters');
    _consume(TokenType.arrow, 'Expected "->" before return type');
    
    Token returnTypeToken = _consumeType('Expected return type');
    
    BlockNode body = _block();
    
    return FunctionDeclNode(
      name: nameToken.lexeme,
      parameters: parameters,
      returnType: returnTypeToken.lexeme,
      body: body,
      line: nameToken.line,
      column: nameToken.column,
    );
  }
  
  VarDeclNode _varDeclaration() {
    bool isConst = _previous().type == TokenType.keywordConst;
    
    Token name = _consume(TokenType.identifier, 'Expected variable name');
    
    String? type;
    if (_match([TokenType.colon])) {
      Token typeToken = _consumeType('Expected type after ":"');
      type = typeToken.lexeme;
    }
    
    ExpressionNode? initializer;
    if (_match([TokenType.assign])) {
      initializer = _expression();
    }
    
    _consume(TokenType.semicolon, 'Expected ";" after variable declaration');
    
    return VarDeclNode(
      name: name.lexeme,
      type: type,
      initializer: initializer,
      isConst: isConst,
      line: name.line,
      column: name.column,
    );
  }
  
  StatementNode _statement() {
    if (_match([TokenType.keywordReturn])) {
      return _returnStatement();
    }
    if (_match([TokenType.keywordIf])) {
      return _ifStatement();
    }
    if (_match([TokenType.leftBrace])) {
      return _block();
    }
    
    return _expressionStatement();
  }
  
  ReturnNode _returnStatement() {
    Token keyword = _previous();
    ExpressionNode? value;
    
    if (!_check(TokenType.semicolon)) {
      value = _expression();
    }
    
    _consume(TokenType.semicolon, 'Expected ";" after return value');
    
    return ReturnNode(value, line: keyword.line, column: keyword.column);
  }
  
  IfNode _ifStatement() {
    Token keyword = _previous();
    
    _consume(TokenType.leftParen, 'Expected "(" after "if"');
    ExpressionNode condition = _expression();
    _consume(TokenType.rightParen, 'Expected ")" after condition');
    
    StatementNode thenBranch = _statement();
    StatementNode? elseBranch;
    
    if (_match([TokenType.keywordElse])) {
      elseBranch = _statement();
    }
    
    return IfNode(
      condition: condition,
      thenBranch: thenBranch,
      elseBranch: elseBranch,
      line: keyword.line,
      column: keyword.column,
    );
  }
  
  BlockNode _block() {
    Token brace = _previous();
    List<StatementNode> statements = [];
    
    while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
      statements.add(_declaration());
    }
    
    _consume(TokenType.rightBrace, 'Expected "}" after block');
    
    return BlockNode(statements, line: brace.line, column: brace.column);
  }
  
  ExpressionStatementNode _expressionStatement() {
    ExpressionNode expr = _expression();
    _consume(TokenType.semicolon, 'Expected ";" after expression');
    
    return ExpressionStatementNode(expr, line: expr.line, column: expr.column);
  }
  
  ExpressionNode _expression() {
    return _assignment();
  }
  
  ExpressionNode _assignment() {
    ExpressionNode expr = _or();
    
    if (_match([TokenType.assign])) {
      Token equals = _previous();
      ExpressionNode value = _assignment();
      
      if (expr is IdentifierNode) {
        return AssignmentNode(
          name: expr.name,
          value: value,
          line: equals.line,
          column: equals.column,
        );
      }
      
      _error('Invalid assignment target', equals);
    }
    
    return expr;
  }
  
  ExpressionNode _or() {
    ExpressionNode expr = _and();
    
    while (_match([TokenType.or])) {
      Token operator = _previous();
      ExpressionNode right = _and();
      expr = BinaryNode(
        left: expr,
        operator: operator.type,
        right: right,
        line: operator.line,
        column: operator.column,
      );
    }
    
    return expr;
  }
  
  ExpressionNode _and() {
    ExpressionNode expr = _equality();
    
    while (_match([TokenType.and])) {
      Token operator = _previous();
      ExpressionNode right = _equality();
      expr = BinaryNode(
        left: expr,
        operator: operator.type,
        right: right,
        line: operator.line,
        column: operator.column,
      );
    }
    
    return expr;
  }
  
  ExpressionNode _equality() {
    ExpressionNode expr = _comparison();
    
    while (_match([TokenType.equal, TokenType.notEqual])) {
      Token operator = _previous();
      ExpressionNode right = _comparison();
      expr = BinaryNode(
        left: expr,
        operator: operator.type,
        right: right,
        line: operator.line,
        column: operator.column,
      );
    }
    
    return expr;
  }
  
  ExpressionNode _comparison() {
    ExpressionNode expr = _term();
    
    while (_match([
      TokenType.greaterThan,
      TokenType.greaterThanEqual,
      TokenType.lessThan,
      TokenType.lessThanEqual,
    ])) {
      Token operator = _previous();
      ExpressionNode right = _term();
      expr = BinaryNode(
        left: expr,
        operator: operator.type,
        right: right,
        line: operator.line,
        column: operator.column,
      );
    }
    
    return expr;
  }
  
  ExpressionNode _term() {
    ExpressionNode expr = _factor();
    
    while (_match([TokenType.minus, TokenType.plus])) {
      Token operator = _previous();
      ExpressionNode right = _factor();
      expr = BinaryNode(
        left: expr,
        operator: operator.type,
        right: right,
        line: operator.line,
        column: operator.column,
      );
    }
    
    return expr;
  }
  
  ExpressionNode _factor() {
    ExpressionNode expr = _unary();
    
    while (_match([TokenType.divide, TokenType.multiply, TokenType.modulo])) {
      Token operator = _previous();
      ExpressionNode right = _unary();
      expr = BinaryNode(
        left: expr,
        operator: operator.type,
        right: right,
        line: operator.line,
        column: operator.column,
      );
    }
    
    return expr;
  }
  
  ExpressionNode _unary() {
    if (_match([TokenType.not, TokenType.minus])) {
      Token operator = _previous();
      ExpressionNode right = _unary();
      return UnaryNode(
        operator: operator.type,
        operand: right,
        line: operator.line,
        column: operator.column,
      );
    }
    
    return _call();
  }
  
  ExpressionNode _call() {
    ExpressionNode expr = _primary();
    
    while (true) {
      if (_match([TokenType.leftParen])) {
        expr = _finishCall(expr);
      } else if (_match([TokenType.dot])) {
        Token name = _consume(TokenType.identifier, 'Expected property name after "."');
        expr = MemberNode(
          object: expr,
          member: name.lexeme,
          line: name.line,
          column: name.column,
        );
      } else {
        break;
      }
    }
    
    return expr;
  }
  
  ExpressionNode _finishCall(ExpressionNode callee) {
    List<ExpressionNode> arguments = [];
    
    if (!_check(TokenType.rightParen)) {
      do {
        arguments.add(_expression());
      } while (_match([TokenType.comma]));
    }
    
    Token paren = _consume(TokenType.rightParen, 'Expected ")" after arguments');
    
    return CallNode(
      callee: callee,
      arguments: arguments,
      line: paren.line,
      column: paren.column,
    );
  }
  
  ExpressionNode _primary() {
    if (_match([TokenType.number, TokenType.string])) {
      Token token = _previous();
      return LiteralNode(token.literal, line: token.line, column: token.column);
    }
    
    if (_match([TokenType.identifier])) {
      Token token = _previous();
      return IdentifierNode(token.lexeme, line: token.line, column: token.column);
    }
    
    if (_match([TokenType.leftParen])) {
      ExpressionNode expr = _expression();
      _consume(TokenType.rightParen, 'Expected ")" after expression');
      return expr;
    }
    
    throw _error('Expected expression', _peek());
  }
  
  Token _consumeType(String message) {
    List<TokenType> types = [
      TokenType.typeFloat,
      TokenType.typeInt,
      TokenType.typeVec2,
      TokenType.typeVec3,
      TokenType.typeVec4,
      TokenType.typeMat2,
      TokenType.typeMat3,
      TokenType.typeMat4,
      TokenType.typeSampler2D,
      TokenType.typeSamplerCube,
    ];
    
    if (_matchAny(types)) {
      return _previous();
    }
    
    throw _error(message, _peek());
  }
  
  bool _match(List<TokenType> types) {
    for (TokenType type in types) {
      if (_check(type)) {
        _advance();
        return true;
      }
    }
    return false;
  }
  
  bool _matchAny(List<TokenType> types) {
    return _match(types);
  }
  
  bool _check(TokenType type) {
    if (_isAtEnd()) return false;
    return _peek().type == type;
  }
  
  Token _advance() {
    if (!_isAtEnd()) _current++;
    return _previous();
  }
  
  bool _isAtEnd() {
    return _peek().type == TokenType.eof;
  }
  
  Token _peek() {
    return tokens[_current];
  }
  
  Token _previous() {
    return tokens[_current - 1];
  }
  
  Token _consume(TokenType type, String message) {
    if (_check(type)) return _advance();
    throw _error(message, _peek());
  }
  
  TSLParseError _error(String message, Token token) {
    return TSLParseError(message, line: token.line, column: token.column);
  }
  
  void _synchronize() {
    _advance();
    
    while (!_isAtEnd()) {
      if (_previous().type == TokenType.semicolon) return;
      
      switch (_peek().type) {
        case TokenType.keywordFn:
        case TokenType.keywordVar:
        case TokenType.keywordConst:
        case TokenType.keywordReturn:
        case TokenType.keywordIf:
        case TokenType.keywordFor:
        case TokenType.keywordWhile:
          return;
        default:
          break;
      }
      
      _advance();
    }
  }
}
