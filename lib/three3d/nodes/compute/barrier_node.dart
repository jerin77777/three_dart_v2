import '../core/node.dart';
import '../core/node_builder.dart';

/// BarrierNode provides synchronization between compute shader invocations.
/// 
/// Barriers ensure that all invocations in a workgroup reach the same point
/// before any continue execution. This is essential for coordinating access
/// to shared memory.
/// 
/// Barrier types:
/// - 'workgroup': Synchronizes all invocations in a workgroup (barrier())
/// - 'memory': Memory barrier for shared memory (memoryBarrierShared())
/// - 'buffer': Memory barrier for buffer memory (memoryBarrierBuffer())
/// - 'image': Memory barrier for image memory (memoryBarrierImage())
/// 
/// Requirements: 7.4
/// 
/// Example:
/// ```dart
/// // Workgroup barrier - wait for all threads
/// BarrierNode workgroupBarrier = BarrierNode('workgroup');
/// 
/// // Memory barrier for shared memory
/// BarrierNode memoryBarrier = BarrierNode('memory');
/// ```
class BarrierNode extends Node {
  /// The type of barrier
  String barrierType;
  
  /// Valid barrier types
  static const Set<String> validBarrierTypes = {
    'workgroup',
    'memory',
    'buffer',
    'image',
  };
  
  /// GLSL function names for barriers
  static const Map<String, String> glslFunctionNames = {
    'workgroup': 'barrier',
    'memory': 'memoryBarrierShared',
    'buffer': 'memoryBarrierBuffer',
    'image': 'memoryBarrierImage',
  };
  
  BarrierNode(this.barrierType) : super() {
    nodeType = 'BarrierNode';
    
    if (!validBarrierTypes.contains(barrierType)) {
      throw ArgumentError(
        'Invalid barrier type: $barrierType. '
        'Valid types are: ${validBarrierTypes.join(", ")}'
      );
    }
  }
  
  @override
  String build(NodeBuilder builder, String output) {
    // Verify we're in compute shader stage
    if (builder.shaderStage != 'compute') {
      throw StateError(
        'BarrierNode can only be used in compute shaders. '
        'Current stage: ${builder.shaderStage}'
      );
    }
    
    String glslFunction = glslFunctionNames[barrierType]!;
    builder.addFlowCode('$glslFunction();');
    
    return '';
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    // Barriers are statements, not expressions
    return '';
  }
  
  @override
  Node getHash(NodeBuilder builder) {
    return this;
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['barrierType'] = barrierType;
    return json;
  }
  
  // Convenience factory methods
  
  /// Creates a workgroup barrier
  static BarrierNode workgroup() {
    return BarrierNode('workgroup');
  }
  
  /// Creates a shared memory barrier
  static BarrierNode memory() {
    return BarrierNode('memory');
  }
  
  /// Creates a buffer memory barrier
  static BarrierNode buffer() {
    return BarrierNode('buffer');
  }
  
  /// Creates an image memory barrier
  static BarrierNode image() {
    return BarrierNode('image');
  }
}
