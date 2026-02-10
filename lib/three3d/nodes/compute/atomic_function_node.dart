import '../core/node.dart';
import '../core/node_builder.dart';

/// AtomicFunctionNode performs atomic operations on shared memory.
/// 
/// Atomic operations are thread-safe operations that ensure data consistency
/// when multiple compute shader invocations access the same memory location.
/// 
/// Supported operations:
/// - add: Atomic addition
/// - sub: Atomic subtraction (atomicAdd with negated value)
/// - max: Atomic maximum
/// - min: Atomic minimum
/// - and: Atomic bitwise AND
/// - or: Atomic bitwise OR
/// - xor: Atomic bitwise XOR
/// - exchange: Atomic exchange (swap)
/// - compSwap: Atomic compare and swap
/// 
/// Requirements: 7.3
/// 
/// Example:
/// ```dart
/// // Atomic addition
/// AtomicFunctionNode atomicAdd = AtomicFunctionNode(
///   'add',
///   pointerNode: storageBufferNode,
///   valueNode: FloatNode(1.0)
/// );
/// 
/// // Atomic maximum
/// AtomicFunctionNode atomicMax = AtomicFunctionNode(
///   'max',
///   pointerNode: sharedMemoryNode,
///   valueNode: computedValue
/// );
/// ```
class AtomicFunctionNode extends Node {
  /// The atomic operation to perform
  String operation;
  
  /// Node representing the memory location (pointer)
  Node pointerNode;
  
  /// Node representing the value to use in the operation
  Node valueNode;
  
  /// For compare-and-swap, the comparison value
  Node? compareNode;
  
  /// Valid atomic operations
  static const Set<String> validOperations = {
    'add',
    'sub',
    'max',
    'min',
    'and',
    'or',
    'xor',
    'exchange',
    'compSwap',
  };
  
  /// GLSL function names for atomic operations
  static const Map<String, String> glslFunctionNames = {
    'add': 'atomicAdd',
    'sub': 'atomicAdd', // Special case: use atomicAdd with negated value
    'max': 'atomicMax',
    'min': 'atomicMin',
    'and': 'atomicAnd',
    'or': 'atomicOr',
    'xor': 'atomicXor',
    'exchange': 'atomicExchange',
    'compSwap': 'atomicCompSwap',
  };
  
  AtomicFunctionNode(
    this.operation, {
    required this.pointerNode,
    required this.valueNode,
    this.compareNode,
  }) : super() {
    nodeType = 'AtomicFunctionNode';
    
    if (!validOperations.contains(operation)) {
      throw ArgumentError(
        'Invalid atomic operation: $operation. '
        'Valid operations are: ${validOperations.join(", ")}'
      );
    }
    
    if (operation == 'compSwap' && compareNode == null) {
      throw ArgumentError(
        'compareNode is required for compSwap operation'
      );
    }
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    // Verify we're in compute shader stage
    if (builder.shaderStage != 'compute') {
      throw StateError(
        'AtomicFunctionNode can only be used in compute shaders. '
        'Current stage: ${builder.shaderStage}'
      );
    }
    
    String pointer = pointerNode.build(builder, 'auto');
    String value = valueNode.build(builder, 'auto');
    String glslFunction = glslFunctionNames[operation]!;
    
    // Special case for subtraction: negate the value
    if (operation == 'sub') {
      return '$glslFunction($pointer, -($value))';
    }
    
    // Special case for compare-and-swap
    if (operation == 'compSwap') {
      String compare = compareNode!.build(builder, 'auto');
      return '$glslFunction($pointer, $compare, $value)';
    }
    
    // Standard atomic operation
    return '$glslFunction($pointer, $value)';
  }
  
  @override
  Node getHash(NodeBuilder builder) {
    return this;
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['operation'] = operation;
    json['pointerNode'] = pointerNode.toJSON();
    json['valueNode'] = valueNode.toJSON();
    if (compareNode != null) {
      json['compareNode'] = compareNode!.toJSON();
    }
    return json;
  }
  
  // Convenience factory methods
  
  /// Creates an atomic add operation
  static AtomicFunctionNode atomicAdd(Node pointer, Node value) {
    return AtomicFunctionNode('add', pointerNode: pointer, valueNode: value);
  }
  
  /// Creates an atomic subtract operation
  static AtomicFunctionNode atomicSub(Node pointer, Node value) {
    return AtomicFunctionNode('sub', pointerNode: pointer, valueNode: value);
  }
  
  /// Creates an atomic max operation
  static AtomicFunctionNode atomicMax(Node pointer, Node value) {
    return AtomicFunctionNode('max', pointerNode: pointer, valueNode: value);
  }
  
  /// Creates an atomic min operation
  static AtomicFunctionNode atomicMin(Node pointer, Node value) {
    return AtomicFunctionNode('min', pointerNode: pointer, valueNode: value);
  }
  
  /// Creates an atomic AND operation
  static AtomicFunctionNode atomicAnd(Node pointer, Node value) {
    return AtomicFunctionNode('and', pointerNode: pointer, valueNode: value);
  }
  
  /// Creates an atomic OR operation
  static AtomicFunctionNode atomicOr(Node pointer, Node value) {
    return AtomicFunctionNode('or', pointerNode: pointer, valueNode: value);
  }
  
  /// Creates an atomic XOR operation
  static AtomicFunctionNode atomicXor(Node pointer, Node value) {
    return AtomicFunctionNode('xor', pointerNode: pointer, valueNode: value);
  }
  
  /// Creates an atomic exchange operation
  static AtomicFunctionNode atomicExchange(Node pointer, Node value) {
    return AtomicFunctionNode('exchange', pointerNode: pointer, valueNode: value);
  }
  
  /// Creates an atomic compare-and-swap operation
  static AtomicFunctionNode atomicCompSwap(Node pointer, Node compare, Node value) {
    return AtomicFunctionNode(
      'compSwap',
      pointerNode: pointer,
      valueNode: value,
      compareNode: compare,
    );
  }
}
