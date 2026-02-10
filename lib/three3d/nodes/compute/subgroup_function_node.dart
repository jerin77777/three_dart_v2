import '../core/node.dart';
import '../core/node_builder.dart';

/// SubgroupFunctionNode provides access to subgroup operations.
/// 
/// Subgroups are a smaller unit of execution within a workgroup that can
/// perform operations more efficiently. Subgroup operations allow threads
/// within a subgroup to communicate and share data.
/// 
/// Supported operations:
/// - 'barrier': Subgroup barrier
/// - 'elect': Returns true for one invocation in the subgroup
/// - 'all': Returns true if value is true for all invocations
/// - 'any': Returns true if value is true for any invocation
/// - 'broadcast': Broadcast value from one invocation to all
/// - 'add': Sum values across subgroup
/// - 'mul': Multiply values across subgroup
/// - 'min': Minimum value across subgroup
/// - 'max': Maximum value across subgroup
/// 
/// Requirements: 7.5
/// 
/// Example:
/// ```dart
/// // Check if all threads have a condition true
/// SubgroupFunctionNode allTrue = SubgroupFunctionNode(
///   'all',
///   valueNode: conditionNode
/// );
/// 
/// // Sum values across subgroup
/// SubgroupFunctionNode sum = SubgroupFunctionNode(
///   'add',
///   valueNode: valueNode
/// );
/// ```
class SubgroupFunctionNode extends Node {
  /// The subgroup operation to perform
  String operation;
  
  /// Node representing the value (for operations that need it)
  Node? valueNode;
  
  /// For broadcast operation, the invocation ID to broadcast from
  Node? idNode;
  
  /// Valid subgroup operations
  static const Set<String> validOperations = {
    'barrier',
    'elect',
    'all',
    'any',
    'broadcast',
    'add',
    'mul',
    'min',
    'max',
  };
  
  /// GLSL function names for subgroup operations
  static const Map<String, String> glslFunctionNames = {
    'barrier': 'subgroupBarrier',
    'elect': 'subgroupElect',
    'all': 'subgroupAll',
    'any': 'subgroupAny',
    'broadcast': 'subgroupBroadcast',
    'add': 'subgroupAdd',
    'mul': 'subgroupMul',
    'min': 'subgroupMin',
    'max': 'subgroupMax',
  };
  
  SubgroupFunctionNode(
    this.operation, {
    this.valueNode,
    this.idNode,
  }) : super() {
    nodeType = 'SubgroupFunctionNode';
    
    if (!validOperations.contains(operation)) {
      throw ArgumentError(
        'Invalid subgroup operation: $operation. '
        'Valid operations are: ${validOperations.join(", ")}'
      );
    }
    
    // Validate required parameters
    if (operation != 'barrier' && operation != 'elect' && valueNode == null) {
      throw ArgumentError(
        'valueNode is required for $operation operation'
      );
    }
    
    if (operation == 'broadcast' && idNode == null) {
      throw ArgumentError(
        'idNode is required for broadcast operation'
      );
    }
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    // Verify we're in compute shader stage
    if (builder.shaderStage != 'compute') {
      throw StateError(
        'SubgroupFunctionNode can only be used in compute shaders. '
        'Current stage: ${builder.shaderStage}'
      );
    }
    
    String glslFunction = glslFunctionNames[operation]!;
    
    // Operations without parameters
    if (operation == 'barrier' || operation == 'elect') {
      return '$glslFunction()';
    }
    
    // Broadcast operation
    if (operation == 'broadcast') {
      String value = valueNode!.build(builder, 'auto');
      String id = idNode!.build(builder, 'uint');
      return '$glslFunction($value, $id)';
    }
    
    // Standard operations with value parameter
    String value = valueNode!.build(builder, 'auto');
    return '$glslFunction($value)';
  }
  
  @override
  Node getHash(NodeBuilder builder) {
    return this;
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['operation'] = operation;
    if (valueNode != null) {
      json['valueNode'] = valueNode!.toJSON();
    }
    if (idNode != null) {
      json['idNode'] = idNode!.toJSON();
    }
    return json;
  }
  
  // Convenience factory methods
  
  /// Creates a subgroup barrier
  static SubgroupFunctionNode barrier() {
    return SubgroupFunctionNode('barrier');
  }
  
  /// Creates a subgroup elect operation
  static SubgroupFunctionNode elect() {
    return SubgroupFunctionNode('elect');
  }
  
  /// Creates a subgroup all operation
  static SubgroupFunctionNode subgroupAll(Node value) {
    return SubgroupFunctionNode('all', valueNode: value);
  }
  
  /// Creates a subgroup any operation
  static SubgroupFunctionNode subgroupAny(Node value) {
    return SubgroupFunctionNode('any', valueNode: value);
  }
  
  /// Creates a subgroup broadcast operation
  static SubgroupFunctionNode broadcast(Node value, Node id) {
    return SubgroupFunctionNode('broadcast', valueNode: value, idNode: id);
  }
  
  /// Creates a subgroup add operation
  static SubgroupFunctionNode subgroupAdd(Node value) {
    return SubgroupFunctionNode('add', valueNode: value);
  }
  
  /// Creates a subgroup multiply operation
  static SubgroupFunctionNode subgroupMul(Node value) {
    return SubgroupFunctionNode('mul', valueNode: value);
  }
  
  /// Creates a subgroup min operation
  static SubgroupFunctionNode subgroupMin(Node value) {
    return SubgroupFunctionNode('min', valueNode: value);
  }
  
  /// Creates a subgroup max operation
  static SubgroupFunctionNode subgroupMax(Node value) {
    return SubgroupFunctionNode('max', valueNode: value);
  }
}
