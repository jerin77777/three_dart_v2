import 'package:three_dart_v2/three3d/core/index.dart';

/// Represents a vertex attribute in the shader.
/// 
/// Attributes are per-vertex data inputs to the vertex shader,
/// such as position, normal, UV coordinates, etc.
class NodeAttribute {
  /// Attribute variable name in the shader
  final String name;
  
  /// GLSL type of the attribute (e.g., 'vec3', 'vec2', 'vec4')
  final String type;
  
  /// Buffer attribute containing the data
  BufferAttribute? bufferAttribute;
  
  /// Attribute location (set by renderer)
  int? location;
  
  /// Whether the attribute is enabled
  bool enabled = true;
  
  NodeAttribute({
    required this.name,
    required this.type,
    this.bufferAttribute,
  });
  
  // ============================================================================
  // Binding Methods
  // ============================================================================
  
  /// Bind the attribute to a WebGL context
  void bind(dynamic gl, int attributeLocation) {
    if (!enabled || bufferAttribute == null) return;
    
    location = attributeLocation;
    
    // The actual binding logic would be handled by the renderer
    // This is a placeholder for the interface
  }
  
  /// Unbind the attribute
  void unbind(dynamic gl) {
    if (location == null) return;
    
    // Disable the attribute
    // gl.disableVertexAttribArray(location);
  }
  
  /// Enable the attribute
  void enable() {
    enabled = true;
  }
  
  /// Disable the attribute
  void disable() {
    enabled = false;
  }
  
  // ============================================================================
  // Serialization
  // ============================================================================
  
  /// Convert to JSON representation
  Map<String, dynamic> toJSON() {
    return {
      'name': name,
      'type': type,
      'enabled': enabled,
    };
  }
}
