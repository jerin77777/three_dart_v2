import 'node.dart';
import 'node_frame.dart';

/// Represents a shader uniform variable.
/// 
/// Uniforms are global shader parameters that remain constant across
/// all shader invocations for a single draw call.
class NodeUniform {
  /// Uniform variable name in the shader
  final String name;
  
  /// GLSL type of the uniform (e.g., 'float', 'vec3', 'sampler2D')
  final String type;
  
  /// Node that provides the uniform value (optional)
  final Node? node;
  
  /// Current uniform value
  dynamic value;
  
  /// Whether the uniform needs to be updated
  bool needsUpdate = true;
  
  /// Cached uniform location (set by renderer)
  dynamic location;
  
  NodeUniform({
    required this.name,
    required this.type,
    required this.node,
    this.value,
  });
  
  // ============================================================================
  // Update Methods
  // ============================================================================
  
  /// Update the uniform value from the node
  void updateValue(NodeFrame frame) {
    // The actual value extraction would depend on the node type
    // For now, mark as needing update
    needsUpdate = true;
  }
  
  /// Upload the uniform value to the GPU
  void upload(dynamic gl, dynamic uniformLocation) {
    if (!needsUpdate) return;
    
    // The actual upload logic would depend on the type and GL context
    // This is a placeholder for the interface
    location = uniformLocation;
    needsUpdate = false;
  }
  
  /// Mark the uniform as needing an update
  void markNeedsUpdate() {
    needsUpdate = true;
  }
  
  // ============================================================================
  // Serialization
  // ============================================================================
  
  /// Convert to JSON representation
  Map<String, dynamic> toJSON() {
    return {
      'name': name,
      'type': type,
      if (node != null) 'node': node!.toJSON(),
      'value': value,
    };
  }
}
