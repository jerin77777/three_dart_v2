import '../core/node.dart';
import '../core/node_builder.dart';

/// Node that implements conditional logic (ternary operator).
/// 
/// Evaluates a condition and returns one of two values based on the result.
/// Generates GLSL ternary operator: `condition ? ifTrue : ifFalse`
/// 
/// Example:
/// ```dart
/// // If x > 0.5, return 1.0, else return 0.0
/// var conditional = ConditionalNode(
///   OperatorNode('>', xNode, ConstantNode(0.5)),
///   ConstantNode(1.0),
///   ConstantNode(0.0)
/// );
/// ```
class ConditionalNode extends Node {
  /// The condition to evaluate (should produce a boolean)
  final Node condNode;
  
  /// Value to return if condition is true
  final Node ifNode;
  
  /// Value to return if condition is false
  final Node elseNode;
  
  ConditionalNode(this.condNode, this.ifNode, this.elseNode) {
    nodeType = 'ConditionalNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    // Build all dependencies
    condNode.build(builder, 'bool');
    ifNode.build(builder, 'auto');
    elseNode.build(builder, 'auto');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    String cond = condNode.build(builder, 'bool');
    String ifValue = ifNode.build(builder, output);
    String elseValue = elseNode.build(builder, output);
    
    // Generate ternary operator
    return '($cond ? $ifValue : $elseValue)';
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['condNode'] = condNode.toJSON();
    json['ifNode'] = ifNode.toJSON();
    json['elseNode'] = elseNode.toJSON();
    return json;
  }
  
  /// Create a ConditionalNode from JSON
  static ConditionalNode? fromJSON(Map<String, dynamic> json) {
    Node? condNode = Node.fromJSON(json['condNode']);
    Node? ifNode = Node.fromJSON(json['ifNode']);
    Node? elseNode = Node.fromJSON(json['elseNode']);
    
    if (condNode == null || ifNode == null || elseNode == null) {
      return null;
    }
    
    return ConditionalNode(condNode, ifNode, elseNode);
  }
}

/// Node that implements a select operation.
/// 
/// Similar to ConditionalNode but can work with vector conditions,
/// selecting components individually.
/// 
/// Example:
/// ```dart
/// // Select between two vec3 values based on a bvec3 condition
/// var select = SelectNode(conditionVec, trueVec, falseVec);
/// ```
class SelectNode extends Node {
  /// The condition (can be scalar or vector boolean)
  final Node condNode;
  
  /// Value to select if condition is true
  final Node trueNode;
  
  /// Value to select if condition is false
  final Node falseNode;
  
  SelectNode(this.condNode, this.trueNode, this.falseNode) {
    nodeType = 'SelectNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    condNode.build(builder, 'auto');
    trueNode.build(builder, 'auto');
    falseNode.build(builder, 'auto');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    String cond = condNode.build(builder, 'auto');
    String trueValue = trueNode.build(builder, output);
    String falseValue = falseNode.build(builder, output);
    
    // Use GLSL mix with boolean condition
    // mix(a, b, condition) where condition is bvec
    return 'mix($falseValue, $trueValue, $cond)';
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['condNode'] = condNode.toJSON();
    json['trueNode'] = trueNode.toJSON();
    json['falseNode'] = falseNode.toJSON();
    return json;
  }
  
  /// Create a SelectNode from JSON
  static SelectNode? fromJSON(Map<String, dynamic> json) {
    Node? condNode = Node.fromJSON(json['condNode']);
    Node? trueNode = Node.fromJSON(json['trueNode']);
    Node? falseNode = Node.fromJSON(json['falseNode']);
    
    if (condNode == null || trueNode == null || falseNode == null) {
      return null;
    }
    
    return SelectNode(condNode, trueNode, falseNode);
  }
}

// ============================================================================
// Convenience Functions
// ============================================================================

/// Create a conditional node (ternary operator)
/// 
/// Returns `ifTrue` if `condition` is true, otherwise returns `ifFalse`.
ConditionalNode conditional(Node condition, Node ifTrue, Node ifFalse) {
  return ConditionalNode(condition, ifTrue, ifFalse);
}

/// Create a select node
/// 
/// Similar to conditional but works with vector conditions.
SelectNode select(Node condition, Node trueValue, Node falseValue) {
  return SelectNode(condition, trueValue, falseValue);
}

/// Create a conditional that returns 1.0 if condition is true, 0.0 otherwise
ConditionalNode boolToFloat(Node condition) {
  return ConditionalNode(
    condition,
    ConstantNode(1.0),
    ConstantNode(0.0),
  );
}

/// Create a conditional that clamps a value to a range
/// 
/// If value < min, returns min. If value > max, returns max. Otherwise returns value.
Node clampConditional(Node value, Node minVal, Node maxVal) {
  return ConditionalNode(
    OperatorNode('<', value, minVal),
    minVal,
    ConditionalNode(
      OperatorNode('>', value, maxVal),
      maxVal,
      value,
    ),
  );
}

/// Create a step function using conditional
/// 
/// Returns 0.0 if x < edge, otherwise returns 1.0
ConditionalNode stepConditional(Node edge, Node x) {
  return ConditionalNode(
    OperatorNode('<', x, edge),
    ConstantNode(0.0),
    ConstantNode(1.0),
  );
}
