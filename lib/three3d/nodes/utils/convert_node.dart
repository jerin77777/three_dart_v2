import '../core/node.dart';
import '../core/node_builder.dart';

/// Node that performs type conversions between GLSL types.
/// 
/// Handles conversions between scalars, vectors, and matrices.
/// Supports automatic type promotion and component extraction.
/// 
/// Example:
/// ```dart
/// // Convert float to vec3 (broadcast)
/// var vec3Node = ConvertNode(floatNode, 'vec3');
/// 
/// // Convert vec4 to float (extract first component)
/// var floatNode = ConvertNode(vec4Node, 'float');
/// 
/// // Convert int to float
/// var floatNode = ConvertNode(intNode, 'float');
/// ```
class ConvertNode extends Node {
  /// The node to convert
  final Node node;
  
  /// Target type to convert to
  final String targetType;
  
  /// Supported scalar types
  static const Set<String> scalarTypes = {
    'float', 'int', 'uint', 'bool',
  };
  
  /// Supported vector types
  static const Set<String> vectorTypes = {
    'vec2', 'vec3', 'vec4',
    'ivec2', 'ivec3', 'ivec4',
    'uvec2', 'uvec3', 'uvec4',
    'bvec2', 'bvec3', 'bvec4',
  };
  
  /// Supported matrix types
  static const Set<String> matrixTypes = {
    'mat2', 'mat3', 'mat4',
  };
  
  /// All supported types
  static Set<String> get allTypes => {
    ...scalarTypes,
    ...vectorTypes,
    ...matrixTypes,
  };
  
  ConvertNode(this.node, this.targetType) {
    nodeType = 'ConvertNode';
    
    // Validate target type
    if (!allTypes.contains(targetType)) {
      throw ArgumentError(
        'Unknown target type: $targetType. '
        'Supported types: ${allTypes.join(', ')}'
      );
    }
  }
  
  @override
  void analyze(NodeBuilder builder) {
    node.build(builder, 'auto');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    String value = node.build(builder, 'auto');
    String sourceType = builder.getType(node);
    
    // No conversion needed if types match
    if (sourceType == targetType) {
      return value;
    }
    
    // Handle special conversion cases
    return _convertType(value, sourceType, targetType);
  }
  
  /// Perform type conversion with appropriate GLSL syntax
  String _convertType(String value, String sourceType, String targetType) {
    // Scalar to scalar conversions
    if (scalarTypes.contains(sourceType) && scalarTypes.contains(targetType)) {
      return '$targetType($value)';
    }
    
    // Scalar to vector (broadcast)
    if (scalarTypes.contains(sourceType) && vectorTypes.contains(targetType)) {
      return '$targetType($value)';
    }
    
    // Vector to scalar (extract first component)
    if (vectorTypes.contains(sourceType) && scalarTypes.contains(targetType)) {
      return '$targetType($value.x)';
    }
    
    // Vector to vector conversions
    if (vectorTypes.contains(sourceType) && vectorTypes.contains(targetType)) {
      return _convertVector(value, sourceType, targetType);
    }
    
    // Matrix conversions
    if (matrixTypes.contains(sourceType) && matrixTypes.contains(targetType)) {
      return '$targetType($value)';
    }
    
    // Default: direct cast
    return '$targetType($value)';
  }
  
  /// Convert between vector types
  String _convertVector(String value, String sourceType, String targetType) {
    int sourceSize = _getVectorSize(sourceType);
    int targetSize = _getVectorSize(targetType);
    
    if (sourceSize == targetSize) {
      // Same size, just change component type
      return '$targetType($value)';
    } else if (sourceSize > targetSize) {
      // Truncate: extract components
      String components = _getComponentString(targetSize);
      return '$targetType($value.$components)';
    } else {
      // Extend: pad with zeros or ones
      String padding = _getPadding(targetSize - sourceSize);
      return '$targetType($value, $padding)';
    }
  }
  
  /// Get the size of a vector type (2, 3, or 4)
  int _getVectorSize(String type) {
    if (type.contains('2')) return 2;
    if (type.contains('3')) return 3;
    if (type.contains('4')) return 4;
    return 1;
  }
  
  /// Get component swizzle string for size
  String _getComponentString(int size) {
    switch (size) {
      case 2: return 'xy';
      case 3: return 'xyz';
      case 4: return 'xyzw';
      default: return 'x';
    }
  }
  
  /// Get padding values for vector extension
  String _getPadding(int count) {
    List<String> values = List.filled(count, '0.0');
    return values.join(', ');
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['node'] = node.toJSON();
    json['targetType'] = targetType;
    return json;
  }
  
  /// Create a ConvertNode from JSON
  static ConvertNode? fromJSON(Map<String, dynamic> json) {
    String? targetType = json['targetType'];
    if (targetType == null) return null;
    
    Node? node = Node.fromJSON(json['node']);
    if (node == null) return null;
    
    return ConvertNode(node, targetType);
  }
}

// ============================================================================
// Convenience Functions
// ============================================================================

/// Convert node to float
ConvertNode toFloat(Node node) => ConvertNode(node, 'float');

/// Convert node to int
ConvertNode toInt(Node node) => ConvertNode(node, 'int');

/// Convert node to uint
ConvertNode toUint(Node node) => ConvertNode(node, 'uint');

/// Convert node to bool
ConvertNode toBool(Node node) => ConvertNode(node, 'bool');

/// Convert node to vec2
ConvertNode toVec2(Node node) => ConvertNode(node, 'vec2');

/// Convert node to vec3
ConvertNode toVec3(Node node) => ConvertNode(node, 'vec3');

/// Convert node to vec4
ConvertNode toVec4(Node node) => ConvertNode(node, 'vec4');

/// Convert node to ivec2
ConvertNode toIVec2(Node node) => ConvertNode(node, 'ivec2');

/// Convert node to ivec3
ConvertNode toIVec3(Node node) => ConvertNode(node, 'ivec3');

/// Convert node to ivec4
ConvertNode toIVec4(Node node) => ConvertNode(node, 'ivec4');

/// Convert node to uvec2
ConvertNode toUVec2(Node node) => ConvertNode(node, 'uvec2');

/// Convert node to uvec3
ConvertNode toUVec3(Node node) => ConvertNode(node, 'uvec3');

/// Convert node to uvec4
ConvertNode toUVec4(Node node) => ConvertNode(node, 'uvec4');

/// Convert node to bvec2
ConvertNode toBVec2(Node node) => ConvertNode(node, 'bvec2');

/// Convert node to bvec3
ConvertNode toBVec3(Node node) => ConvertNode(node, 'bvec3');

/// Convert node to bvec4
ConvertNode toBVec4(Node node) => ConvertNode(node, 'bvec4');

/// Convert node to mat2
ConvertNode toMat2(Node node) => ConvertNode(node, 'mat2');

/// Convert node to mat3
ConvertNode toMat3(Node node) => ConvertNode(node, 'mat3');

/// Convert node to mat4
ConvertNode toMat4(Node node) => ConvertNode(node, 'mat4');
