import 'node.dart';

/// Represents data passed from vertex shader to fragment shader.
/// 
/// Varyings are interpolated across the primitive (triangle) surface,
/// allowing per-vertex data to be smoothly interpolated to per-fragment data.
class NodeVarying {
  /// Varying variable name in the shader
  final String name;
  
  /// GLSL type of the varying (e.g., 'vec2', 'vec3', 'vec4')
  final String type;
  
  /// Node that provides the varying value
  final Node node;
  
  /// Whether the varying needs interpolation
  bool needsInterpolation = true;
  
  /// Interpolation qualifier ('smooth', 'flat', 'noperspective')
  String interpolation = 'smooth';
  
  NodeVarying({
    required this.name,
    required this.type,
    required this.node,
    this.needsInterpolation = true,
    this.interpolation = 'smooth',
  });
  
  // ============================================================================
  // Code Generation
  // ============================================================================
  
  /// Get the vertex shader declaration for this varying
  String getVertexDeclaration() {
    if (interpolation != 'smooth') {
      return '$interpolation out $type $name;';
    }
    return 'out $type $name;';
  }
  
  /// Get the fragment shader declaration for this varying
  String getFragmentDeclaration() {
    if (interpolation != 'smooth') {
      return '$interpolation in $type $name;';
    }
    return 'in $type $name;';
  }
  
  /// Set interpolation mode
  void setInterpolation(String mode) {
    if (mode == 'smooth' || mode == 'flat' || mode == 'noperspective') {
      interpolation = mode;
    } else {
      throw ArgumentError('Invalid interpolation mode: $mode');
    }
  }
  
  // ============================================================================
  // Serialization
  // ============================================================================
  
  /// Convert to JSON representation
  Map<String, dynamic> toJSON() {
    return {
      'name': name,
      'type': type,
      'node': node.toJSON(),
      'interpolation': interpolation,
      'needsInterpolation': needsInterpolation,
    };
  }
}
