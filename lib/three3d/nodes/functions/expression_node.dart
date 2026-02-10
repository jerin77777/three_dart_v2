import '../core/node.dart';
import '../core/node_builder.dart';

/// Node that represents an inline shader expression.
/// 
/// ExpressionNode is similar to CodeNode but is designed for single-line
/// expressions rather than multi-line code blocks. It's useful for simple
/// custom operations that don't warrant a full CodeNode.
/// 
/// Example:
/// ```dart
/// ExpressionNode expr = ExpressionNode(
///   'smoothstep(\${edge0}, \${edge1}, \${x})',
///   includes: {
///     'edge0': edge0Node,
///     'edge1': edge1Node,
///     'x': xNode,
///   }
/// );
/// ```
class ExpressionNode extends Node {
  /// The GLSL expression
  final String expression;
  
  /// Map of placeholder names to nodes that provide their values
  final Map<String, Node>? includes;
  
  /// Optional explicit return type for the expression
  final String? returnType;
  
  ExpressionNode(
    this.expression, {
    this.includes,
    this.returnType,
  }) {
    nodeType = 'ExpressionNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    // Build all included nodes during analysis phase
    if (includes != null) {
      for (var node in includes!.values) {
        node.build(builder, 'auto');
      }
    }
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    String result = expression;
    
    // Replace placeholders with node values
    if (includes != null) {
      includes!.forEach((key, node) {
        // Determine the appropriate output type for this node
        String nodeOutput = returnType ?? output;
        String value = node.build(builder, nodeOutput);
        
        // Replace ${key} with the node's generated code
        result = result.replaceAll('\${$key}', value);
      });
    }
    
    // Wrap in parentheses to ensure proper precedence
    return '($result)';
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['expression'] = expression;
    
    if (returnType != null) {
      json['returnType'] = returnType;
    }
    
    if (includes != null && includes!.isNotEmpty) {
      Map<String, dynamic> includesJson = {};
      includes!.forEach((key, node) {
        includesJson[key] = node.toJSON();
      });
      json['includes'] = includesJson;
    }
    
    return json;
  }
}
