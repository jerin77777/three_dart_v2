import 'package:three_dart_v2/three3d/math/index.dart';
import 'node_builder.dart';

/// Base class for all nodes in the node material system.
/// 
/// Nodes are the fundamental building blocks that represent shader operations
/// or data sources. They can be connected to form complex shader graphs.
abstract class Node {
  /// Unique identifier for this node instance
  late String uuid;
  
  /// Type identifier for this node (e.g., 'TextureNode', 'MathNode')
  String? nodeType;
  
  /// User-defined data storage
  Map<String, dynamic>? userData;
  
  /// Whether this node has been built
  bool _isBuilt = false;
  
  Node() {
    uuid = MathUtils.generateUUID();
  }
  
  // ============================================================================
  // Core Build Methods
  // ============================================================================
  
  /// Get a hash representing this node's configuration.
  /// Used for caching and detecting changes.
  Node? getHash(NodeBuilder builder) {
    return this;
  }
  
  /// Build this node in the given builder context.
  /// This is the main entry point for node compilation.
  String build(NodeBuilder builder, String output) {
    if (_isBuilt) {
      return getCachedCode(builder, output);
    }
    
    _isBuilt = true;
    
    // Analyze dependencies
    analyze(builder);
    
    // Generate code
    return generate(builder, output);
  }
  
  /// Analyze this node's dependencies and requirements.
  /// Called during the analyze phase of compilation.
  void analyze(NodeBuilder builder) {
    // Default implementation - override in subclasses
  }
  
  /// Generate shader code for this node.
  /// Returns the GLSL expression representing this node's output.
  String generate(NodeBuilder builder, String output);
  
  /// Get cached code for this node if available
  String getCachedCode(NodeBuilder builder, String output) {
    if (builder.isNodeCached(this)) {
      return builder.getCachedNode(this);
    }
    return generate(builder, output);
  }
  
  // ============================================================================
  // Type Conversion Methods
  // ============================================================================
  
  /// Convert this node to a float value
  Node toFloat() {
    return ConvertNode(this, 'float');
  }
  
  /// Convert this node to an int value
  Node toInt() {
    return ConvertNode(this, 'int');
  }
  
  /// Convert this node to a uint value
  Node toUint() {
    return ConvertNode(this, 'uint');
  }
  
  /// Convert this node to a bool value
  Node toBool() {
    return ConvertNode(this, 'bool');
  }
  
  /// Convert this node to a vec2
  Node toVec2() {
    return ConvertNode(this, 'vec2');
  }
  
  /// Convert this node to a vec3
  Node toVec3() {
    return ConvertNode(this, 'vec3');
  }
  
  /// Convert this node to a vec4
  Node toVec4() {
    return ConvertNode(this, 'vec4');
  }
  
  /// Convert this node to a mat2
  Node toMat2() {
    return ConvertNode(this, 'mat2');
  }
  
  /// Convert this node to a mat3
  Node toMat3() {
    return ConvertNode(this, 'mat3');
  }
  
  /// Convert this node to a mat4
  Node toMat4() {
    return ConvertNode(this, 'mat4');
  }
  
  // ============================================================================
  // Operator Methods
  // ============================================================================
  
  /// Add another value to this node
  Node add(dynamic value) {
    return OperatorNode('+', this, _convertToNode(value));
  }
  
  /// Subtract another value from this node
  Node sub(dynamic value) {
    return OperatorNode('-', this, _convertToNode(value));
  }
  
  /// Multiply this node by another value
  Node mul(dynamic value) {
    return OperatorNode('*', this, _convertToNode(value));
  }
  
  /// Divide this node by another value
  Node div(dynamic value) {
    return OperatorNode('/', this, _convertToNode(value));
  }
  
  /// Modulo operation
  Node mod(dynamic value) {
    return OperatorNode('%', this, _convertToNode(value));
  }
  
  /// Power operation
  Node pow(dynamic value) {
    return MathNode('pow', this, _convertToNode(value));
  }
  
  /// Dot product (for vectors)
  Node dot(dynamic value) {
    return MathNode('dot', this, _convertToNode(value));
  }
  
  /// Cross product (for vec3)
  Node cross(dynamic value) {
    return MathNode('cross', this, _convertToNode(value));
  }
  
  /// Convert a value to a Node if it isn't already
  Node _convertToNode(dynamic value) {
    if (value is Node) {
      return value;
    } else if (value is num) {
      return ConstantNode(value.toDouble());
    } else if (value is Vector2) {
      return Vec2Node(value.x.toDouble(), value.y.toDouble());
    } else if (value is Vector3) {
      return Vec3Node(value.x.toDouble(), value.y.toDouble(), value.z.toDouble());
    } else if (value is Vector4) {
      return Vec4Node(value.x.toDouble(), value.y.toDouble(), value.z.toDouble(), value.w.toDouble());
    } else {
      throw ArgumentError('Cannot convert $value to Node');
    }
  }
  
  // ============================================================================
  // Serialization Methods
  // ============================================================================
  
  /// Serialize this node to JSON
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = {
      'uuid': uuid,
      'type': nodeType ?? runtimeType.toString(),
    };
    
    if (userData != null && userData!.isNotEmpty) {
      json['userData'] = userData;
    }
    
    return json;
  }
  
  /// Deserialize a node from JSON
  static Node? fromJSON(Map<String, dynamic> json) {
    // This will be implemented as nodes are added
    // For now, return null for unknown types
    String? type = json['type'];
    
    if (type == null) {
      return null;
    }
    
    // Node type registry will be populated as nodes are implemented
    return null;
  }
  
  /// Reset the build state (useful for rebuilding)
  void reset() {
    _isBuilt = false;
  }
}

// ============================================================================
// Helper Node Classes
// ============================================================================

/// Node that performs type conversion
class ConvertNode extends Node {
  final Node node;
  final String targetType;
  
  ConvertNode(this.node, this.targetType) {
    nodeType = 'ConvertNode';
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    String value = node.build(builder, 'auto');
    String sourceType = builder.getType(node);
    
    if (sourceType == targetType) {
      return value;
    }
    
    return '$targetType($value)';
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['node'] = node.toJSON();
    json['targetType'] = targetType;
    return json;
  }
}

/// Node that performs arithmetic operations
class OperatorNode extends Node {
  final String op;
  final Node aNode;
  final Node bNode;
  
  OperatorNode(this.op, this.aNode, this.bNode) {
    nodeType = 'OperatorNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    aNode.build(builder, 'auto');
    bNode.build(builder, 'auto');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    String a = aNode.build(builder, output);
    String b = bNode.build(builder, output);
    return '($a $op $b)';
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['op'] = op;
    json['aNode'] = aNode.toJSON();
    json['bNode'] = bNode.toJSON();
    return json;
  }
}

/// Node that performs mathematical functions
class MathNode extends Node {
  final String method;
  final Node aNode;
  final Node? bNode;
  final Node? cNode;
  
  MathNode(this.method, this.aNode, [this.bNode, this.cNode]) {
    nodeType = 'MathNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    aNode.build(builder, 'auto');
    bNode?.build(builder, 'auto');
    cNode?.build(builder, 'auto');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    String a = aNode.build(builder, output);
    
    if (bNode == null) {
      return '$method($a)';
    }
    
    String b = bNode!.build(builder, output);
    
    if (cNode == null) {
      return '$method($a, $b)';
    }
    
    String c = cNode!.build(builder, output);
    return '$method($a, $b, $c)';
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['method'] = method;
    json['aNode'] = aNode.toJSON();
    if (bNode != null) json['bNode'] = bNode!.toJSON();
    if (cNode != null) json['cNode'] = cNode!.toJSON();
    return json;
  }
}

/// Node representing a constant value
class ConstantNode extends Node {
  final double value;
  
  ConstantNode(this.value) {
    nodeType = 'ConstantNode';
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    // Format the number appropriately for GLSL
    if (value == value.toInt()) {
      return '${value.toInt()}.0';
    }
    return value.toString();
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['value'] = value;
    return json;
  }
}

/// Node representing a vec2 constant
class Vec2Node extends Node {
  final double x;
  final double y;
  
  Vec2Node(this.x, this.y) {
    nodeType = 'Vec2Node';
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    return 'vec2(${_formatFloat(x)}, ${_formatFloat(y)})';
  }
  
  String _formatFloat(double value) {
    if (value == value.toInt()) {
      return '${value.toInt()}.0';
    }
    return value.toString();
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['x'] = x;
    json['y'] = y;
    return json;
  }
}

/// Node representing a vec3 constant
class Vec3Node extends Node {
  final double x;
  final double y;
  final double z;
  
  Vec3Node(this.x, this.y, this.z) {
    nodeType = 'Vec3Node';
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    return 'vec3(${_formatFloat(x)}, ${_formatFloat(y)}, ${_formatFloat(z)})';
  }
  
  String _formatFloat(double value) {
    if (value == value.toInt()) {
      return '${value.toInt()}.0';
    }
    return value.toString();
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['x'] = x;
    json['y'] = y;
    json['z'] = z;
    return json;
  }
}

/// Node representing a vec4 constant
class Vec4Node extends Node {
  final double x;
  final double y;
  final double z;
  final double w;
  
  Vec4Node(this.x, this.y, this.z, this.w) {
    nodeType = 'Vec4Node';
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    return 'vec4(${_formatFloat(x)}, ${_formatFloat(y)}, ${_formatFloat(z)}, ${_formatFloat(w)})';
  }
  
  String _formatFloat(double value) {
    if (value == value.toInt()) {
      return '${value.toInt()}.0';
    }
    return value.toString();
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['x'] = x;
    json['y'] = y;
    json['z'] = z;
    json['w'] = w;
    return json;
  }
}
