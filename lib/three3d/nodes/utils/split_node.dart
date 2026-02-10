import '../core/node.dart';
import '../core/node_builder.dart';

/// Node that extracts components from vectors.
/// 
/// Uses GLSL swizzle syntax to extract one or more components
/// from a vector. Supports all standard swizzle patterns.
/// 
/// Example:
/// ```dart
/// // Extract x component from vec3
/// var xNode = SplitNode(vec3Node, 'x');
/// 
/// // Extract xy components from vec4
/// var xyNode = SplitNode(vec4Node, 'xy');
/// 
/// // Extract rgb components (same as xyz)
/// var rgbNode = SplitNode(vec4Node, 'rgb');
/// 
/// // Swizzle: extract components in different order
/// var zyxNode = SplitNode(vec3Node, 'zyx');
/// ```
class SplitNode extends Node {
  /// The node to extract components from
  final Node node;
  
  /// Component swizzle pattern (e.g., 'x', 'xy', 'rgb', 'xyzw')
  final String components;
  
  /// Valid component characters for xyzw notation
  static const Set<String> xyzwComponents = {'x', 'y', 'z', 'w'};
  
  /// Valid component characters for rgba notation
  static const Set<String> rgbaComponents = {'r', 'g', 'b', 'a'};
  
  /// Valid component characters for stpq notation (texture coordinates)
  static const Set<String> stpqComponents = {'s', 't', 'p', 'q'};
  
  SplitNode(this.node, this.components) {
    nodeType = 'SplitNode';
    
    if (components.isEmpty) {
      throw ArgumentError('SplitNode requires at least one component');
    }
    
    if (components.length > 4) {
      throw ArgumentError(
        'SplitNode supports maximum 4 components, got ${components.length}'
      );
    }
    
    // Validate components
    _validateComponents(components);
  }
  
  /// Validate that all components are valid and consistent
  void _validateComponents(String components) {
    if (components.isEmpty) return;
    
    // Determine which notation is being used
    String firstChar = components[0];
    Set<String> validSet;
    
    if (xyzwComponents.contains(firstChar)) {
      validSet = xyzwComponents;
    } else if (rgbaComponents.contains(firstChar)) {
      validSet = rgbaComponents;
    } else if (stpqComponents.contains(firstChar)) {
      validSet = stpqComponents;
    } else {
      throw ArgumentError(
        'Invalid component: $firstChar. '
        'Valid components: xyzw, rgba, or stpq'
      );
    }
    
    // Validate all components use the same notation
    for (int i = 0; i < components.length; i++) {
      String char = components[i];
      if (!validSet.contains(char)) {
        throw ArgumentError(
          'Invalid or mixed component notation at position $i: $char. '
          'All components must use the same notation (xyzw, rgba, or stpq)'
        );
      }
    }
  }
  
  @override
  void analyze(NodeBuilder builder) {
    node.build(builder, 'auto');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    String value = node.build(builder, 'auto');
    
    // Generate swizzle access
    return '$value.$components';
  }
  
  /// Get the output type based on component count
  String getOutputType() {
    switch (components.length) {
      case 1: return 'float';
      case 2: return 'vec2';
      case 3: return 'vec3';
      case 4: return 'vec4';
      default: return 'float';
    }
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['node'] = node.toJSON();
    json['components'] = components;
    return json;
  }
  
  /// Create a SplitNode from JSON
  static SplitNode? fromJSON(Map<String, dynamic> json) {
    String? components = json['components'];
    if (components == null) return null;
    
    Node? node = Node.fromJSON(json['node']);
    if (node == null) return null;
    
    return SplitNode(node, components);
  }
}

// ============================================================================
// Convenience Functions
// ============================================================================

/// Extract x component
SplitNode x(Node node) => SplitNode(node, 'x');

/// Extract y component
SplitNode y(Node node) => SplitNode(node, 'y');

/// Extract z component
SplitNode z(Node node) => SplitNode(node, 'z');

/// Extract w component
SplitNode w(Node node) => SplitNode(node, 'w');

/// Extract xy components
SplitNode xy(Node node) => SplitNode(node, 'xy');

/// Extract xyz components
SplitNode xyz(Node node) => SplitNode(node, 'xyz');

/// Extract xyzw components
SplitNode xyzw(Node node) => SplitNode(node, 'xyzw');

/// Extract r component (same as x)
SplitNode r(Node node) => SplitNode(node, 'r');

/// Extract g component (same as y)
SplitNode g(Node node) => SplitNode(node, 'g');

/// Extract b component (same as z)
SplitNode b(Node node) => SplitNode(node, 'b');

/// Extract a component (same as w)
SplitNode a(Node node) => SplitNode(node, 'a');

/// Extract rgb components
SplitNode rgb(Node node) => SplitNode(node, 'rgb');

/// Extract rgba components
SplitNode rgba(Node node) => SplitNode(node, 'rgba');

/// Extract custom swizzle pattern
SplitNode swizzle(Node node, String pattern) => SplitNode(node, pattern);
