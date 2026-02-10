import '../core/node.dart';
import '../core/node_builder.dart';

/// Node that performs arithmetic operations.
/// 
/// Supports standard arithmetic operators: +, -, *, /, %
/// Also supports comparison and logical operators.
/// 
/// Example:
/// ```dart
/// // Addition: a + b
/// var addNode = OperatorNode('+', aNode, bNode);
/// 
/// // Multiplication: a * b
/// var mulNode = OperatorNode('*', aNode, bNode);
/// 
/// // Comparison: a < b
/// var ltNode = OperatorNode('<', aNode, bNode);
/// ```
class OperatorNode extends Node {
  /// The operator to apply
  final String op;
  
  /// Left operand
  final Node aNode;
  
  /// Right operand
  final Node bNode;
  
  /// Supported arithmetic operators
  static const Set<String> arithmeticOps = {
    '+', '-', '*', '/', '%',
  };
  
  /// Supported comparison operators
  static const Set<String> comparisonOps = {
    '==', '!=', '<', '<=', '>', '>=',
  };
  
  /// Supported logical operators
  static const Set<String> logicalOps = {
    '&&', '||',
  };
  
  /// Supported bitwise operators
  static const Set<String> bitwiseOps = {
    '&', '|', '^', '<<', '>>',
  };
  
  /// All supported operators
  static Set<String> get allOps => {
    ...arithmeticOps,
    ...comparisonOps,
    ...logicalOps,
    ...bitwiseOps,
  };
  
  OperatorNode(this.op, this.aNode, this.bNode) {
    nodeType = 'OperatorNode';
    
    // Validate operator
    if (!allOps.contains(op)) {
      throw ArgumentError(
        'Unknown operator: $op. '
        'Supported operators: ${allOps.join(', ')}'
      );
    }
  }
  
  @override
  void analyze(NodeBuilder builder) {
    // Build dependencies
    aNode.build(builder, 'auto');
    bNode.build(builder, 'auto');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    String a = aNode.build(builder, output);
    String b = bNode.build(builder, output);
    
    // Wrap in parentheses to ensure correct precedence
    return '($a $op $b)';
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['op'] = op;
    json['aNode'] = aNode.toJSON();
    json['bNode'] = bNode.toJSON();
    return json;
  }
  
  /// Create an OperatorNode from JSON
  static OperatorNode? fromJSON(Map<String, dynamic> json) {
    String? op = json['op'];
    if (op == null) return null;
    
    Node? aNode = Node.fromJSON(json['aNode']);
    Node? bNode = Node.fromJSON(json['bNode']);
    
    if (aNode == null || bNode == null) return null;
    
    return OperatorNode(op, aNode, bNode);
  }
  
  /// Check if this is an arithmetic operator
  bool get isArithmetic => arithmeticOps.contains(op);
  
  /// Check if this is a comparison operator
  bool get isComparison => comparisonOps.contains(op);
  
  /// Check if this is a logical operator
  bool get isLogical => logicalOps.contains(op);
  
  /// Check if this is a bitwise operator
  bool get isBitwise => bitwiseOps.contains(op);
}

// ============================================================================
// Convenience Functions
// ============================================================================

/// Create an addition node (a + b)
OperatorNode add(Node a, Node b) => OperatorNode('+', a, b);

/// Create a subtraction node (a - b)
OperatorNode sub(Node a, Node b) => OperatorNode('-', a, b);

/// Create a multiplication node (a * b)
OperatorNode mul(Node a, Node b) => OperatorNode('*', a, b);

/// Create a division node (a / b)
OperatorNode div(Node a, Node b) => OperatorNode('/', a, b);

/// Create a modulo node (a % b)
OperatorNode modulo(Node a, Node b) => OperatorNode('%', a, b);

/// Create an equality comparison node (a == b)
OperatorNode equal(Node a, Node b) => OperatorNode('==', a, b);

/// Create an inequality comparison node (a != b)
OperatorNode notEqual(Node a, Node b) => OperatorNode('!=', a, b);

/// Create a less-than comparison node (a < b)
OperatorNode lessThan(Node a, Node b) => OperatorNode('<', a, b);

/// Create a less-than-or-equal comparison node (a <= b)
OperatorNode lessThanEqual(Node a, Node b) => OperatorNode('<=', a, b);

/// Create a greater-than comparison node (a > b)
OperatorNode greaterThan(Node a, Node b) => OperatorNode('>', a, b);

/// Create a greater-than-or-equal comparison node (a >= b)
OperatorNode greaterThanEqual(Node a, Node b) => OperatorNode('>=', a, b);

/// Create a logical AND node (a && b)
OperatorNode and(Node a, Node b) => OperatorNode('&&', a, b);

/// Create a logical OR node (a || b)
OperatorNode or(Node a, Node b) => OperatorNode('||', a, b);

/// Create a bitwise AND node (a & b)
OperatorNode bitwiseAnd(Node a, Node b) => OperatorNode('&', a, b);

/// Create a bitwise OR node (a | b)
OperatorNode bitwiseOr(Node a, Node b) => OperatorNode('|', a, b);

/// Create a bitwise XOR node (a ^ b)
OperatorNode bitwiseXor(Node a, Node b) => OperatorNode('^', a, b);

/// Create a left shift node (a << b)
OperatorNode leftShift(Node a, Node b) => OperatorNode('<<', a, b);

/// Create a right shift node (a >> b)
OperatorNode rightShift(Node a, Node b) => OperatorNode('>>', a, b);
