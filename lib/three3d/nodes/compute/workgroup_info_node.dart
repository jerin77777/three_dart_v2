import '../core/node.dart';
import '../core/node_builder.dart';

/// WorkgroupInfoNode provides access to workgroup information.
/// 
/// This node provides information about the workgroup configuration and
/// execution context, such as workgroup size and subgroup information.
/// 
/// Available information:
/// - 'size': Workgroup size (gl_WorkGroupSize)
/// - 'subgroupSize': Size of subgroups (gl_SubgroupSize)
/// - 'numSubgroups': Number of subgroups (gl_NumSubgroups)
/// - 'subgroupID': Current subgroup ID (gl_SubgroupID)
/// 
/// Requirements: 7.6
/// 
/// Example:
/// ```dart
/// // Get workgroup size
/// WorkgroupInfoNode workgroupSize = WorkgroupInfoNode('size');
/// 
/// // Get subgroup size
/// WorkgroupInfoNode subgroupSize = WorkgroupInfoNode('subgroupSize');
/// ```
class WorkgroupInfoNode extends Node {
  /// The type of workgroup information to access
  String infoType;
  
  /// Valid information types
  static const Set<String> validInfoTypes = {
    'size',
    'subgroupSize',
    'numSubgroups',
    'subgroupID',
  };
  
  /// GLSL variable names for workgroup information
  static const Map<String, String> glslVariableNames = {
    'size': 'gl_WorkGroupSize',
    'subgroupSize': 'gl_SubgroupSize',
    'numSubgroups': 'gl_NumSubgroups',
    'subgroupID': 'gl_SubgroupID',
  };
  
  /// Type mapping for workgroup information
  static const Map<String, String> infoTypes = {
    'size': 'uvec3',
    'subgroupSize': 'uint',
    'numSubgroups': 'uint',
    'subgroupID': 'uint',
  };
  
  WorkgroupInfoNode(this.infoType) : super() {
    nodeType = 'WorkgroupInfoNode';
    
    if (!validInfoTypes.contains(infoType)) {
      throw ArgumentError(
        'Invalid workgroup info type: $infoType. '
        'Valid types are: ${validInfoTypes.join(", ")}'
      );
    }
  }
  
  /// Get the GLSL type of this information
  String getInfoGLSLType() {
    return infoTypes[infoType]!;
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    // Verify we're in compute shader stage
    if (builder.shaderStage != 'compute') {
      throw StateError(
        'WorkgroupInfoNode can only be used in compute shaders. '
        'Current stage: ${builder.shaderStage}'
      );
    }
    
    return glslVariableNames[infoType]!;
  }
  
  @override
  Node getHash(NodeBuilder builder) {
    return this;
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['infoType'] = infoType;
    return json;
  }
  
  // Convenience factory methods
  
  /// Creates a node for workgroup size
  static WorkgroupInfoNode size() {
    return WorkgroupInfoNode('size');
  }
  
  /// Creates a node for subgroup size
  static WorkgroupInfoNode subgroupSize() {
    return WorkgroupInfoNode('subgroupSize');
  }
  
  /// Creates a node for number of subgroups
  static WorkgroupInfoNode numSubgroups() {
    return WorkgroupInfoNode('numSubgroups');
  }
  
  /// Creates a node for subgroup ID
  static WorkgroupInfoNode subgroupID() {
    return WorkgroupInfoNode('subgroupID');
  }
}
