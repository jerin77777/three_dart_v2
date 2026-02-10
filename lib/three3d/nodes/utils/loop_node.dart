import '../core/node.dart';
import '../core/node_builder.dart';

/// Node that implements loop control flow in shaders.
/// 
/// Generates GLSL for-loop constructs. Useful for iterative
/// operations like summing values, applying effects multiple times,
/// or processing arrays.
/// 
/// Example:
/// ```dart
/// // Simple for loop: for(int i = 0; i < 10; i++)
/// var loopNode = LoopNode(
///   start: ConstantNode(0),
///   end: ConstantNode(10),
///   body: bodyNode,
/// );
/// 
/// // Loop with custom step
/// var loopNode = LoopNode(
///   start: ConstantNode(0),
///   end: ConstantNode(10),
///   step: ConstantNode(2),
///   body: bodyNode,
/// );
/// ```
class LoopNode extends Node {
  /// Loop start value (initial value of loop variable)
  final Node start;
  
  /// Loop end condition (loop while variable < end)
  final Node end;
  
  /// Loop step (increment per iteration, default 1)
  final Node? step;
  
  /// Loop body node (executed each iteration)
  final Node body;
  
  /// Loop variable name (default 'i')
  final String indexVar;
  
  /// Loop variable type (default 'int')
  final String indexType;
  
  LoopNode({
    required this.start,
    required this.end,
    required this.body,
    this.step,
    this.indexVar = 'i',
    this.indexType = 'int',
  }) {
    nodeType = 'LoopNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    start.build(builder, indexType);
    end.build(builder, indexType);
    step?.build(builder, indexType);
    body.build(builder, 'void');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    String startValue = start.build(builder, indexType);
    String endValue = end.build(builder, indexType);
    String stepValue = step?.build(builder, indexType) ?? '1';
    
    // Generate loop variable name (ensure uniqueness)
    String loopVar = builder.getUniqueVarName(indexVar);
    
    // Build loop body
    String bodyCode = body.build(builder, 'void');
    
    // Generate for loop
    StringBuffer code = StringBuffer();
    code.writeln('for ($indexType $loopVar = $startValue; $loopVar < $endValue; $loopVar += $stepValue) {');
    code.writeln('  $bodyCode');
    code.writeln('}');
    
    return code.toString();
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['start'] = start.toJSON();
    json['end'] = end.toJSON();
    if (step != null) json['step'] = step!.toJSON();
    json['body'] = body.toJSON();
    json['indexVar'] = indexVar;
    json['indexType'] = indexType;
    return json;
  }
  
  /// Create a LoopNode from JSON
  static LoopNode? fromJSON(Map<String, dynamic> json) {
    Node? start = Node.fromJSON(json['start']);
    Node? end = Node.fromJSON(json['end']);
    Node? body = Node.fromJSON(json['body']);
    
    if (start == null || end == null || body == null) return null;
    
    Node? step = json['step'] != null ? Node.fromJSON(json['step']) : null;
    String indexVar = json['indexVar'] ?? 'i';
    String indexType = json['indexType'] ?? 'int';
    
    return LoopNode(
      start: start,
      end: end,
      body: body,
      step: step,
      indexVar: indexVar,
      indexType: indexType,
    );
  }
}

/// Node that implements while loop control flow.
/// 
/// Generates GLSL while-loop constructs.
/// 
/// Example:
/// ```dart
/// // while (condition) { body }
/// var whileNode = WhileNode(
///   condition: conditionNode,
///   body: bodyNode,
/// );
/// ```
class WhileNode extends Node {
  /// Loop condition (loop while this is true)
  final Node condition;
  
  /// Loop body node (executed each iteration)
  final Node body;
  
  WhileNode({
    required this.condition,
    required this.body,
  }) {
    nodeType = 'WhileNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    condition.build(builder, 'bool');
    body.build(builder, 'void');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    String condValue = condition.build(builder, 'bool');
    
    // Build loop body
    String bodyCode = body.build(builder, 'void');
    
    // Generate while loop
    StringBuffer code = StringBuffer();
    code.writeln('while ($condValue) {');
    code.writeln('  $bodyCode');
    code.writeln('}');
    
    return code.toString();
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['condition'] = condition.toJSON();
    json['body'] = body.toJSON();
    return json;
  }
  
  /// Create a WhileNode from JSON
  static WhileNode? fromJSON(Map<String, dynamic> json) {
    Node? condition = Node.fromJSON(json['condition']);
    Node? body = Node.fromJSON(json['body']);
    
    if (condition == null || body == null) return null;
    
    return WhileNode(
      condition: condition,
      body: body,
    );
  }
}

// ============================================================================
// Convenience Functions
// ============================================================================

/// Create a for loop
LoopNode forLoop({
  required Node start,
  required Node end,
  required Node body,
  Node? step,
  String indexVar = 'i',
}) => LoopNode(
  start: start,
  end: end,
  body: body,
  step: step,
  indexVar: indexVar,
);

/// Create a while loop
WhileNode whileLoop({
  required Node condition,
  required Node body,
}) => WhileNode(
  condition: condition,
  body: body,
);
