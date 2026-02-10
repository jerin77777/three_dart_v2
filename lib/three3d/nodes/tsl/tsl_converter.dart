/// TSL to Node Graph Converter
/// 
/// Converts TSL Abstract Syntax Tree (AST) to a node graph that can be
/// compiled into shader code.

import '../core/node.dart';
import '../core/node_builder.dart';
import '../math/operator_node.dart' as op;
import '../math/math_node.dart' as math;
import '../math/conditional_node.dart' as cond;
import '../functions/function_node.dart';
import '../functions/function_call_node.dart';
import '../utils/convert_node.dart' as conv;
import '../utils/join_node.dart' as join;
import '../utils/split_node.dart' as split;
import 'tsl_parser.dart';
import 'tsl_tokenizer.dart';

/// Exception thrown during TSL to node conversion
class TSLConversionError implements Exception {
  final String message;
  final int line;
  final int column;
  
  TSLConversionError(this.message, {required this.line, required this.column});
  
  @override
  String toString() => 'TSL Conversion Error at line $line, column $column: $message';
}

/// Converts TSL AST to node graph
class TSLConverter {
  /// Symbol table for variables and functions
  final Map<String, Node> _variables = {};
  final Map<String, FunctionNode> _functions = {};
  
  /// Convert a TSL program to a node graph
  /// Returns the root node of the graph
  Node convert(ProgramNode program) {
    Node? lastNode;
    
    for (StatementNode statement in program.statements) {
      lastNode = _convertStatement(statement);
    }
    
    if (lastNode == null) {
      throw TSLConversionError(
        'Empty program - no statements to convert',
        line: program.line,
        column: program.column,
      );
    }
    
    return lastNode;
  }
  
  /// Convert a statement to a node
  Node? _convertStatement(StatementNode statement) {
    if (statement is FunctionDeclNode) {
      return _convertFunctionDecl(statement);
    } else if (statement is VarDeclNode) {
      return _convertVarDecl(statement);
    } else if (statement is ReturnNode) {
      return _convertReturn(statement);
    } else if (statement is ExpressionStatementNode) {
      return _convertExpression(statement.expression);
    } else if (statement is BlockNode) {
      return _convertBlock(statement);
    } else if (statement is IfNode) {
      return _convertIf(statement);
    }
    
    throw TSLConversionError(
      'Unsupported statement type: ${statement.runtimeType}',
      line: statement.line,
      column: statement.column,
    );
  }
  
  /// Convert a function declaration
  Node _convertFunctionDecl(FunctionDeclNode decl) {
    // Create function parameters
    List<FunctionParameter> parameters = decl.parameters.map((param) {
      return FunctionParameter(
        name: param.name,
        type: param.type,
      );
    }).toList();
    
    // Convert function body
    Node bodyNode = _convertBlock(decl.body);
    
    // Create function node
    FunctionNode functionNode = FunctionNode(
      name: decl.name,
      parameters: parameters,
      returnType: decl.returnType,
      bodyNode: bodyNode,
    );
    
    // Register function
    _functions[decl.name] = functionNode;
    
    return functionNode;
  }
  
  /// Convert a variable declaration
  Node? _convertVarDecl(VarDeclNode decl) {
    if (decl.initializer == null) {
      throw TSLConversionError(
        'Variable "${decl.name}" must have an initializer',
        line: decl.line,
        column: decl.column,
      );
    }
    
    Node valueNode = _convertExpression(decl.initializer!);
    
    // Apply type conversion if type is specified
    if (decl.type != null) {
      valueNode = _convertType(valueNode, decl.type!);
    }
    
    // Register variable
    _variables[decl.name] = valueNode;
    
    return valueNode;
  }
  
  /// Convert a return statement
  Node _convertReturn(ReturnNode returnNode) {
    if (returnNode.value == null) {
      throw TSLConversionError(
        'Return statement must have a value',
        line: returnNode.line,
        column: returnNode.column,
      );
    }
    
    return _convertExpression(returnNode.value!);
  }
  
  /// Convert a block statement
  Node _convertBlock(BlockNode block) {
    Node? lastNode;
    
    for (StatementNode statement in block.statements) {
      lastNode = _convertStatement(statement);
    }
    
    if (lastNode == null) {
      throw TSLConversionError(
        'Empty block - no statements to convert',
        line: block.line,
        column: block.column,
      );
    }
    
    return lastNode;
  }
  
  /// Convert an if statement
  Node _convertIf(IfNode ifNode) {
    Node condition = _convertExpression(ifNode.condition);
    Node thenBranch = _convertStatement(ifNode.thenBranch)!;
    Node elseBranch = ifNode.elseBranch != null
        ? _convertStatement(ifNode.elseBranch!)!
        : ConstantNode(0.0); // Default else value
    
    // Create conditional node (ternary operator)
    return cond.ConditionalNode(condition, thenBranch, elseBranch);
  }
  
  /// Convert an expression to a node
  Node _convertExpression(ExpressionNode expression) {
    if (expression is BinaryNode) {
      return _convertBinary(expression);
    } else if (expression is UnaryNode) {
      return _convertUnary(expression);
    } else if (expression is CallNode) {
      return _convertCall(expression);
    } else if (expression is MemberNode) {
      return _convertMember(expression);
    } else if (expression is IdentifierNode) {
      return _convertIdentifier(expression);
    } else if (expression is LiteralNode) {
      return _convertLiteral(expression);
    } else if (expression is AssignmentNode) {
      return _convertAssignment(expression);
    }
    
    throw TSLConversionError(
      'Unsupported expression type: ${expression.runtimeType}',
      line: expression.line,
      column: expression.column,
    );
  }
  
  /// Convert a binary expression
  Node _convertBinary(BinaryNode binary) {
    Node left = _convertExpression(binary.left);
    Node right = _convertExpression(binary.right);
    
    // Map token type to operator string
    String opStr = _tokenTypeToOperator(binary.operator);
    
    // Check if it's a comparison or logical operator
    if (_isComparisonOperator(binary.operator) || 
        _isLogicalOperator(binary.operator)) {
      // Use math node for comparisons
      return math.MathNode(opStr, left, right);
    }
    
    // Use operator node for arithmetic
    return op.OperatorNode(opStr, left, right);
  }
  
  /// Convert a unary expression
  Node _convertUnary(UnaryNode unary) {
    Node operand = _convertExpression(unary.operand);
    
    switch (unary.operator) {
      case TokenType.minus:
        return op.OperatorNode('*', ConstantNode(-1.0), operand);
      case TokenType.not:
        return math.MathNode('not', operand);
      default:
        throw TSLConversionError(
          'Unsupported unary operator: ${unary.operator}',
          line: unary.line,
          column: unary.column,
        );
    }
  }
  
  /// Convert a function call
  Node _convertCall(CallNode call) {
    // Get function name
    String? functionName;
    if (call.callee is IdentifierNode) {
      functionName = (call.callee as IdentifierNode).name;
    } else {
      throw TSLConversionError(
        'Function call must use an identifier',
        line: call.line,
        column: call.column,
      );
    }
    
    // Convert arguments
    List<Node> arguments = call.arguments
        .map((arg) => _convertExpression(arg))
        .toList();
    
    // Check if it's a built-in function
    if (_isBuiltInFunction(functionName)) {
      return _convertBuiltInFunction(functionName, arguments, call.line, call.column);
    }
    
    // Check if it's a user-defined function
    if (_functions.containsKey(functionName)) {
      FunctionNode functionNode = _functions[functionName]!;
      return FunctionCallNode(
        functionNode: functionNode,
        arguments: arguments,
      );
    }
    
    throw TSLConversionError(
      'Unknown function: $functionName',
      line: call.line,
      column: call.column,
    );
  }
  
  /// Convert a member access expression
  Node _convertMember(MemberNode member) {
    Node object = _convertExpression(member.object);
    
    // Create a split node to extract the component
    return split.SplitNode(object, member.member);
  }
  
  /// Convert an identifier
  Node _convertIdentifier(IdentifierNode identifier) {
    if (_variables.containsKey(identifier.name)) {
      return _variables[identifier.name]!;
    }
    
    throw TSLConversionError(
      'Undefined variable: ${identifier.name}',
      line: identifier.line,
      column: identifier.column,
    );
  }
  
  /// Convert a literal value
  Node _convertLiteral(LiteralNode literal) {
    return ConstantNode(literal.value is num ? (literal.value as num).toDouble() : 0.0);
  }
  
  /// Convert an assignment
  Node _convertAssignment(AssignmentNode assignment) {
    Node value = _convertExpression(assignment.value);
    _variables[assignment.name] = value;
    return value;
  }
  
  /// Convert a type specification to a type conversion
  Node _convertType(Node node, String type) {
    return conv.ConvertNode(node, type);
  }
  
  /// Map token type to operator string
  String _tokenTypeToOperator(TokenType type) {
    switch (type) {
      case TokenType.plus:
        return '+';
      case TokenType.minus:
        return '-';
      case TokenType.multiply:
        return '*';
      case TokenType.divide:
        return '/';
      case TokenType.modulo:
        return '%';
      case TokenType.equal:
        return 'equal';
      case TokenType.notEqual:
        return 'notEqual';
      case TokenType.lessThan:
        return 'lessThan';
      case TokenType.lessThanEqual:
        return 'lessThanEqual';
      case TokenType.greaterThan:
        return 'greaterThan';
      case TokenType.greaterThanEqual:
        return 'greaterThanEqual';
      case TokenType.and:
        return 'and';
      case TokenType.or:
        return 'or';
      default:
        return '?';
    }
  }
  
  /// Check if token is a comparison operator
  bool _isComparisonOperator(TokenType type) {
    return type == TokenType.equal ||
           type == TokenType.notEqual ||
           type == TokenType.lessThan ||
           type == TokenType.lessThanEqual ||
           type == TokenType.greaterThan ||
           type == TokenType.greaterThanEqual;
  }
  
  /// Check if token is a logical operator
  bool _isLogicalOperator(TokenType type) {
    return type == TokenType.and || type == TokenType.or;
  }
  
  /// Check if a function name is a built-in function
  bool _isBuiltInFunction(String name) {
    const builtIns = [
      'sin', 'cos', 'tan', 'asin', 'acos', 'atan',
      'abs', 'sign', 'floor', 'ceil', 'fract', 'round',
      'sqrt', 'exp', 'log', 'pow',
      'min', 'max', 'clamp', 'mix', 'step', 'smoothstep',
      'length', 'distance', 'dot', 'cross', 'normalize',
      'vec2', 'vec3', 'vec4',
    ];
    return builtIns.contains(name);
  }
  
  /// Convert a built-in function call
  Node _convertBuiltInFunction(String name, List<Node> arguments, int line, int column) {
    // Type constructors
    if (name == 'vec2' || name == 'vec3' || name == 'vec4') {
      if (arguments.isEmpty) {
        throw TSLConversionError(
          'Vector constructor requires at least one argument',
          line: line,
          column: column,
        );
      }
      
      if (arguments.length == 1) {
        // Single argument - convert to vector type
        return conv.ConvertNode(arguments[0], name);
      } else {
        // Multiple arguments - join them
        return join.JoinNode(arguments, outputType: name);
      }
    }
    
    // Math functions
    if (arguments.isEmpty) {
      throw TSLConversionError(
        'Function $name requires at least one argument',
        line: line,
        column: column,
      );
    }
    
    return math.MathNode(
      name,
      arguments[0],
      arguments.length > 1 ? arguments[1] : null,
      arguments.length > 2 ? arguments[2] : null,
    );
  }
}

/// Main entry point for TSL compilation
class TSL {
  /// Parse and convert TSL code to a node graph
  static Node parse(String tslCode) {
    // Tokenize
    TSLTokenizer tokenizer = TSLTokenizer(tslCode);
    List<Token> tokens = tokenizer.tokenize();
    
    // Parse
    TSLParser parser = TSLParser(tokens);
    ProgramNode program = parser.parse();
    
    // Convert to nodes
    TSLConverter converter = TSLConverter();
    return converter.convert(program);
  }
}
