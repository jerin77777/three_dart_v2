import '../core/node.dart';
import '../core/node_builder.dart';

/// ComputeBuiltinNode provides access to compute shader built-in variables.
/// 
/// Compute shaders have several built-in variables that provide information
/// about the current invocation:
/// - gl_GlobalInvocationID: Global work item ID
/// - gl_LocalInvocationID: Local work item ID within workgroup
/// - gl_WorkGroupID: Work group ID
/// - gl_LocalInvocationIndex: 1D index of local invocation
/// - gl_NumWorkGroups: Number of work groups
/// 
/// Requirements: 7.2
/// 
/// Example:
/// ```dart
/// // Get global invocation ID
/// ComputeBuiltinNode globalId = ComputeBuiltinNode('gl_GlobalInvocationID');
/// 
/// // Get local invocation ID
/// ComputeBuiltinNode localId = ComputeBuiltinNode('gl_LocalInvocationID');
/// ```
class ComputeBuiltinNode extends Node {
  /// The name of the built-in variable
  String builtinName;
  
  /// Valid compute shader built-in variable names
  static const Set<String> validBuiltins = {
    'gl_GlobalInvocationID',
    'gl_LocalInvocationID',
    'gl_WorkGroupID',
    'gl_LocalInvocationIndex',
    'gl_NumWorkGroups',
  };
  
  /// Type mapping for built-in variables
  static const Map<String, String> builtinTypes = {
    'gl_GlobalInvocationID': 'uvec3',
    'gl_LocalInvocationID': 'uvec3',
    'gl_WorkGroupID': 'uvec3',
    'gl_LocalInvocationIndex': 'uint',
    'gl_NumWorkGroups': 'uvec3',
  };
  
  ComputeBuiltinNode(this.builtinName) : super() {
    nodeType = 'ComputeBuiltinNode';
    
    if (!validBuiltins.contains(builtinName)) {
      throw ArgumentError(
        'Invalid compute builtin: $builtinName. '
        'Valid builtins are: ${validBuiltins.join(", ")}'
      );
    }
  }
  
  /// Get the GLSL type of this built-in variable
  String getBuiltinType() {
    return builtinTypes[builtinName]!;
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    // Verify we're in compute shader stage
    if (builder.shaderStage != 'compute') {
      throw StateError(
        'ComputeBuiltinNode can only be used in compute shaders. '
        'Current stage: ${builder.shaderStage}'
      );
    }
    
    return builtinName;
  }
  
  @override
  Node getHash(NodeBuilder builder) {
    return this;
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['builtinName'] = builtinName;
    return json;
  }
  
  // Convenience factory methods
  
  /// Creates a node for gl_GlobalInvocationID
  static ComputeBuiltinNode globalInvocationID() {
    return ComputeBuiltinNode('gl_GlobalInvocationID');
  }
  
  /// Creates a node for gl_LocalInvocationID
  static ComputeBuiltinNode localInvocationID() {
    return ComputeBuiltinNode('gl_LocalInvocationID');
  }
  
  /// Creates a node for gl_WorkGroupID
  static ComputeBuiltinNode workGroupID() {
    return ComputeBuiltinNode('gl_WorkGroupID');
  }
  
  /// Creates a node for gl_LocalInvocationIndex
  static ComputeBuiltinNode localInvocationIndex() {
    return ComputeBuiltinNode('gl_LocalInvocationIndex');
  }
  
  /// Creates a node for gl_NumWorkGroups
  static ComputeBuiltinNode numWorkGroups() {
    return ComputeBuiltinNode('gl_NumWorkGroups');
  }
}
