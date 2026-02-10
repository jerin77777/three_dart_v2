import '../core/node.dart';
import '../core/node_builder.dart';

/// Node that combines multiple values into a vector.
/// 
/// Takes multiple scalar or vector inputs and combines them into
/// a single vector output. Useful for constructing vectors from
/// individual components or combining smaller vectors.
/// 
/// Example:
/// ```dart
/// // Create vec3 from three floats
/// var vec3Node = JoinNode([xNode, yNode, zNode]);
/// 
/// // Create vec4 from vec3 and float
/// var vec4Node = JoinNode([vec3Node, wNode]);
/// 
/// // Create vec2 from two floats
/// var vec2Node = JoinNode([xNode, yNode]);
/// ```
class JoinNode extends Node {
  /// Nodes to join together
  final List<Node> nodes;
  
  /// Optional explicit output type
  final String? outputType;
  
  JoinNode(this.nodes, {this.outputType}) {
    nodeType = 'JoinNode';
    
    if (nodes.isEmpty) {
      throw ArgumentError('JoinNode requires at least one input node');
    }
    
    if (nodes.length > 4) {
      throw ArgumentError(
        'JoinNode supports maximum 4 components, got ${nodes.length}'
      );
    }
  }
  
  @override
  void analyze(NodeBuilder builder) {
    // Build all input nodes
    for (var node in nodes) {
      node.build(builder, 'auto');
    }
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    // Build all input values
    List<String> values = [];
    int totalComponents = 0;
    
    for (var node in nodes) {
      String value = node.build(builder, 'auto');
      values.add(value);
      
      // Count components
      String type = builder.getType(node);
      totalComponents += _getComponentCount(type);
    }
    
    // Determine output vector type
    String vecType = outputType ?? _getVectorType(totalComponents);
    
    // Generate constructor call
    return '$vecType(${values.join(', ')})';
  }
  
  /// Get the number of components in a type
  int _getComponentCount(String type) {
    if (type.contains('vec2') || type.contains('2')) return 2;
    if (type.contains('vec3') || type.contains('3')) return 3;
    if (type.contains('vec4') || type.contains('4')) return 4;
    return 1; // Scalar
  }
  
  /// Get the appropriate vector type for component count
  String _getVectorType(int componentCount) {
    switch (componentCount) {
      case 1: return 'float';
      case 2: return 'vec2';
      case 3: return 'vec3';
      case 4: return 'vec4';
      default:
        throw ArgumentError(
          'Cannot create vector with $componentCount components. '
          'Maximum is 4.'
        );
    }
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['nodes'] = nodes.map((n) => n.toJSON()).toList();
    if (outputType != null) {
      json['outputType'] = outputType;
    }
    return json;
  }
  
  /// Create a JoinNode from JSON
  static JoinNode? fromJSON(Map<String, dynamic> json) {
    List<dynamic>? nodesJson = json['nodes'];
    if (nodesJson == null) return null;
    
    List<Node> nodes = [];
    for (var nodeJson in nodesJson) {
      Node? node = Node.fromJSON(nodeJson);
      if (node != null) {
        nodes.add(node);
      }
    }
    
    if (nodes.isEmpty) return null;
    
    String? outputType = json['outputType'];
    return JoinNode(nodes, outputType: outputType);
  }
}

// ============================================================================
// Convenience Functions
// ============================================================================

/// Join nodes into a vec2
JoinNode vec2(Node x, Node y) => JoinNode([x, y], outputType: 'vec2');

/// Join nodes into a vec3
JoinNode vec3(Node x, Node y, Node z) => JoinNode([x, y, z], outputType: 'vec3');

/// Join nodes into a vec4 (from 4 scalars)
JoinNode vec4(Node x, Node y, Node z, Node w) => 
  JoinNode([x, y, z, w], outputType: 'vec4');

/// Join nodes into a vec4 (from vec3 and scalar)
JoinNode vec4FromVec3(Node xyz, Node w) => 
  JoinNode([xyz, w], outputType: 'vec4');

/// Join nodes into a vec3 (from vec2 and scalar)
JoinNode vec3FromVec2(Node xy, Node z) => 
  JoinNode([xy, z], outputType: 'vec3');

/// Join any nodes into appropriate vector type
JoinNode join(List<Node> nodes) => JoinNode(nodes);
