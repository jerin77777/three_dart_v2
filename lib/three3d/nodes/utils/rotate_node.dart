import '../core/node.dart';
import '../core/node_builder.dart';

/// Node that rotates a 2D vector around the origin.
/// 
/// Applies 2D rotation transformation to a vec2 using an angle.
/// 
/// Example:
/// ```dart
/// // Rotate UV coordinates by 45 degrees
/// var rotatedUV = RotateNode(
///   vector: uvNode,
///   angle: ConstantNode(0.785398), // 45 degrees in radians
/// );
/// 
/// // Rotate around custom center
/// var rotatedUV = RotateNode(
///   vector: uvNode,
///   angle: angleNode,
///   center: Vec2Node(0.5, 0.5),
/// );
/// ```
class RotateNode extends Node {
  /// Vector to rotate (vec2)
  final Node vector;
  
  /// Rotation angle in radians
  final Node angle;
  
  /// Center of rotation (default: origin)
  final Node? center;
  
  RotateNode({
    required this.vector,
    required this.angle,
    this.center,
  }) {
    nodeType = 'RotateNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    vector.build(builder, 'vec2');
    angle.build(builder, 'float');
    center?.build(builder, 'vec2');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    String vec = vector.build(builder, 'vec2');
    String ang = angle.build(builder, 'float');
    
    if (center != null) {
      String cnt = center!.build(builder, 'vec2');
      
      // Rotate around custom center
      return '''
        (function() {
          vec2 v = $vec - $cnt;
          float c = cos($ang);
          float s = sin($ang);
          return vec2(
            v.x * c - v.y * s,
            v.x * s + v.y * c
          ) + $cnt;
        })()
      ''';
    } else {
      // Rotate around origin
      return '''
        (function() {
          float c = cos($ang);
          float s = sin($ang);
          vec2 v = $vec;
          return vec2(
            v.x * c - v.y * s,
            v.x * s + v.y * c
          );
        })()
      ''';
    }
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['vector'] = vector.toJSON();
    json['angle'] = angle.toJSON();
    if (center != null) json['center'] = center!.toJSON();
    return json;
  }
  
  /// Create a RotateNode from JSON
  static RotateNode? fromJSON(Map<String, dynamic> json) {
    Node? vector = Node.fromJSON(json['vector']);
    Node? angle = Node.fromJSON(json['angle']);
    
    if (vector == null || angle == null) return null;
    
    Node? center = json['center'] != null ? Node.fromJSON(json['center']) : null;
    
    return RotateNode(
      vector: vector,
      angle: angle,
      center: center,
    );
  }
}

/// Node that rotates a 3D vector around an axis.
/// 
/// Applies 3D rotation transformation using axis-angle representation.
/// 
/// Example:
/// ```dart
/// // Rotate around Y axis
/// var rotated = Rotate3DNode(
///   vector: positionNode,
///   axis: Vec3Node(0, 1, 0),
///   angle: angleNode,
/// );
/// ```
class Rotate3DNode extends Node {
  /// Vector to rotate (vec3)
  final Node vector;
  
  /// Rotation axis (normalized vec3)
  final Node axis;
  
  /// Rotation angle in radians
  final Node angle;
  
  Rotate3DNode({
    required this.vector,
    required this.axis,
    required this.angle,
  }) {
    nodeType = 'Rotate3DNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    vector.build(builder, 'vec3');
    axis.build(builder, 'vec3');
    angle.build(builder, 'float');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    String vec = vector.build(builder, 'vec3');
    String ax = axis.build(builder, 'vec3');
    String ang = angle.build(builder, 'float');
    
    // Use Rodrigues' rotation formula
    return '''
      (function() {
        vec3 v = $vec;
        vec3 k = normalize($ax);
        float a = $ang;
        float c = cos(a);
        float s = sin(a);
        return v * c + cross(k, v) * s + k * dot(k, v) * (1.0 - c);
      })()
    ''';
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['vector'] = vector.toJSON();
    json['axis'] = axis.toJSON();
    json['angle'] = angle.toJSON();
    return json;
  }
  
  /// Create a Rotate3DNode from JSON
  static Rotate3DNode? fromJSON(Map<String, dynamic> json) {
    Node? vector = Node.fromJSON(json['vector']);
    Node? axis = Node.fromJSON(json['axis']);
    Node? angle = Node.fromJSON(json['angle']);
    
    if (vector == null || axis == null || angle == null) return null;
    
    return Rotate3DNode(
      vector: vector,
      axis: axis,
      angle: angle,
    );
  }
}

// ============================================================================
// Convenience Functions
// ============================================================================

/// Rotate 2D vector
RotateNode rotate2D({
  required Node vector,
  required Node angle,
  Node? center,
}) => RotateNode(
  vector: vector,
  angle: angle,
  center: center,
);

/// Rotate 3D vector around axis
Rotate3DNode rotate3D({
  required Node vector,
  required Node axis,
  required Node angle,
}) => Rotate3DNode(
  vector: vector,
  axis: axis,
  angle: angle,
);

/// Rotate around X axis
Rotate3DNode rotateX(Node vector, Node angle) => Rotate3DNode(
  vector: vector,
  axis: Vec3Node(1, 0, 0),
  angle: angle,
);

/// Rotate around Y axis
Rotate3DNode rotateY(Node vector, Node angle) => Rotate3DNode(
  vector: vector,
  axis: Vec3Node(0, 1, 0),
  angle: angle,
);

/// Rotate around Z axis
Rotate3DNode rotateZ(Node vector, Node angle) => Rotate3DNode(
  vector: vector,
  axis: Vec3Node(0, 0, 1),
  angle: angle,
);
