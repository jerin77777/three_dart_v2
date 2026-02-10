import '../core/node.dart';
import '../core/node_builder.dart';

/// ComputeNode defines compute shader operations for GPGPU computing.
/// 
/// Compute shaders enable general-purpose GPU computing, allowing parallel
/// processing of data outside the traditional vertex/fragment pipeline.
/// 
/// Requirements: 7.1
/// 
/// Example:
/// ```dart
/// ComputeNode compute = ComputeNode(
///   computeNode: myComputeLogic,
///   workgroupSize: [8, 8, 1],
///   count: 1024
/// );
/// ```
class ComputeNode extends Node {
  /// The node containing the compute shader logic
  Node computeNode;
  
  /// Workgroup size for compute shader (local_size_x, local_size_y, local_size_z)
  /// Default is [1, 1, 1]
  List<int> workgroupSize;
  
  /// Number of workgroups to dispatch
  int count;
  
  ComputeNode(
    this.computeNode, {
    this.workgroupSize = const [1, 1, 1],
    this.count = 1,
  }) : super() {
    nodeType = 'ComputeNode';
    
    // Validate workgroup size
    if (workgroupSize.length != 3) {
      throw ArgumentError('workgroupSize must have exactly 3 elements');
    }
    
    if (workgroupSize.any((size) => size < 1)) {
      throw ArgumentError('workgroupSize elements must be >= 1');
    }
    
    if (count < 1) {
      throw ArgumentError('count must be >= 1');
    }
  }
  
  @override
  String build(NodeBuilder builder, String output) {
    // Set shader stage to compute
    String previousStage = builder.shaderStage;
    builder.shaderStage = 'compute';
    
    // Add compute shader layout declaration
    builder.addFlowCode(
      'layout(local_size_x = ${workgroupSize[0]}, '
      'local_size_y = ${workgroupSize[1]}, '
      'local_size_z = ${workgroupSize[2]}) in;'
    );
    
    // Build the compute logic
    computeNode.build(builder, 'void');
    
    // Restore previous shader stage
    builder.shaderStage = previousStage;
    
    return '';
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    // Compute nodes don't generate inline code
    // They define the main compute shader structure
    return '';
  }
  
  @override
  Node getHash(NodeBuilder builder) {
    return this;
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['workgroupSize'] = workgroupSize;
    json['count'] = count;
    json['computeNode'] = computeNode.toJSON();
    return json;
  }
}
