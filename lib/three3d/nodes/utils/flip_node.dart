import '../core/node.dart';
import '../core/node_builder.dart';

/// Node that flips/mirrors coordinates.
/// 
/// Flips coordinates along specified axes. Useful for mirroring
/// textures, inverting normals, or creating symmetrical effects.
/// 
/// Example:
/// ```dart
/// // Flip UV horizontally
/// var flippedUV = FlipNode(uvNode, flipX: true);
/// 
/// // Flip UV vertically
/// var flippedUV = FlipNode(uvNode, flipY: true);
/// 
/// // Flip both axes
/// var flippedUV = FlipNode(uvNode, flipX: true, flipY: true);
/// ```
class FlipNode extends Node {
  /// Vector to flip
  final Node vector;
  
  /// Whether to flip X axis
  final bool flipX;
  
  /// Whether to flip Y axis
  final bool flipY;
  
  /// Whether to flip Z axis (for vec3/vec4)
  final bool flipZ;
  
  /// Whether to flip W axis (for vec4)
  final bool flipW;
  
  /// Center point for flipping (default: 0.5 for each axis)
  final Node? center;
  
  FlipNode(
    this.vector, {
    this.flipX = false,
    this.flipY = false,
    this.flipZ = false,
    this.flipW = false,
    this.center,
  }) {
    nodeType = 'FlipNode';
    
    if (!flipX && !flipY && !flipZ && !flipW) {
      throw ArgumentError('FlipNode requires at least one axis to flip');
    }
  }
  
  @override
  void analyze(NodeBuilder builder) {
    vector.build(builder, 'auto');
    center?.build(builder, 'auto');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    String vec = vector.build(builder, output);
    String type = builder.getType(vector);
    
    // Determine center point
    String centerValue;
    if (center != null) {
      centerValue = center!.build(builder, type);
    } else {
      // Default center based on type
      if (type == 'vec2') {
        centerValue = 'vec2(0.5)';
      } else if (type == 'vec3') {
        centerValue = 'vec3(0.5)';
      } else if (type == 'vec4') {
        centerValue = 'vec4(0.5)';
      } else {
        centerValue = '0.5';
      }
    }
    
    // Build flip expression
    List<String> components = [];
    
    if (type == 'float') {
      if (flipX) {
        return '($centerValue - ($vec - $centerValue))';
      }
      return vec;
    }
    
    // For vectors, flip individual components
    if (type.contains('vec2')) {
      components.add(flipX ? '($centerValue.x - ($vec.x - $centerValue.x))' : '$vec.x');
      components.add(flipY ? '($centerValue.y - ($vec.y - $centerValue.y))' : '$vec.y');
      return 'vec2(${components.join(', ')})';
    }
    
    if (type.contains('vec3')) {
      components.add(flipX ? '($centerValue.x - ($vec.x - $centerValue.x))' : '$vec.x');
      components.add(flipY ? '($centerValue.y - ($vec.y - $centerValue.y))' : '$vec.y');
      components.add(flipZ ? '($centerValue.z - ($vec.z - $centerValue.z))' : '$vec.z');
      return 'vec3(${components.join(', ')})';
    }
    
    if (type.contains('vec4')) {
      components.add(flipX ? '($centerValue.x - ($vec.x - $centerValue.x))' : '$vec.x');
      components.add(flipY ? '($centerValue.y - ($vec.y - $centerValue.y))' : '$vec.y');
      components.add(flipZ ? '($centerValue.z - ($vec.z - $centerValue.z))' : '$vec.z');
      components.add(flipW ? '($centerValue.w - ($vec.w - $centerValue.w))' : '$vec.w');
      return 'vec4(${components.join(', ')})';
    }
    
    return vec;
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['vector'] = vector.toJSON();
    json['flipX'] = flipX;
    json['flipY'] = flipY;
    json['flipZ'] = flipZ;
    json['flipW'] = flipW;
    if (center != null) json['center'] = center!.toJSON();
    return json;
  }
  
  /// Create a FlipNode from JSON
  static FlipNode? fromJSON(Map<String, dynamic> json) {
    Node? vector = Node.fromJSON(json['vector']);
    if (vector == null) return null;
    
    bool flipX = json['flipX'] ?? false;
    bool flipY = json['flipY'] ?? false;
    bool flipZ = json['flipZ'] ?? false;
    bool flipW = json['flipW'] ?? false;
    Node? center = json['center'] != null ? Node.fromJSON(json['center']) : null;
    
    return FlipNode(
      vector,
      flipX: flipX,
      flipY: flipY,
      flipZ: flipZ,
      flipW: flipW,
      center: center,
    );
  }
}

/// Node that inverts a value (1 - value).
/// 
/// Useful for inverting colors, masks, or other normalized values.
/// 
/// Example:
/// ```dart
/// // Invert color
/// var inverted = InvertNode(colorNode);
/// 
/// // Invert with custom range
/// var inverted = InvertNode(valueNode, max: ConstantNode(255));
/// ```
class InvertNode extends Node {
  /// Value to invert
  final Node value;
  
  /// Maximum value for inversion (default: 1.0)
  final Node? max;
  
  InvertNode(this.value, {this.max}) {
    nodeType = 'InvertNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    value.build(builder, 'auto');
    max?.build(builder, 'auto');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    String val = value.build(builder, output);
    String maxValue = max?.build(builder, output) ?? '1.0';
    
    return '($maxValue - $val)';
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['value'] = value.toJSON();
    if (max != null) json['max'] = max!.toJSON();
    return json;
  }
  
  /// Create an InvertNode from JSON
  static InvertNode? fromJSON(Map<String, dynamic> json) {
    Node? value = Node.fromJSON(json['value']);
    if (value == null) return null;
    
    Node? max = json['max'] != null ? Node.fromJSON(json['max']) : null;
    
    return InvertNode(value, max: max);
  }
}

// ============================================================================
// Convenience Functions
// ============================================================================

/// Flip vector along specified axes
FlipNode flip(
  Node vector, {
  bool flipX = false,
  bool flipY = false,
  bool flipZ = false,
  bool flipW = false,
  Node? center,
}) => FlipNode(
  vector,
  flipX: flipX,
  flipY: flipY,
  flipZ: flipZ,
  flipW: flipW,
  center: center,
);

/// Flip horizontally (X axis)
FlipNode flipX(Node vector, {Node? center}) => 
  FlipNode(vector, flipX: true, center: center);

/// Flip vertically (Y axis)
FlipNode flipY(Node vector, {Node? center}) => 
  FlipNode(vector, flipY: true, center: center);

/// Flip along Z axis
FlipNode flipZ(Node vector, {Node? center}) => 
  FlipNode(vector, flipZ: true, center: center);

/// Invert value (1 - value)
InvertNode invert(Node value, {Node? max}) => 
  InvertNode(value, max: max);
