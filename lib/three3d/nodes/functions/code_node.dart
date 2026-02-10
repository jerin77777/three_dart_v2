import '../core/node.dart';
import '../core/node_builder.dart';

/// Node that embeds raw shader code.
/// 
/// CodeNode allows developers to inject custom GLSL code directly into the
/// shader. It supports placeholder substitution for dynamic values from other nodes.
/// 
/// Example:
/// ```dart
/// CodeNode customCode = CodeNode(
///   'vec3 result = mix(\${colorA}, \${colorB}, \${factor});',
///   includes: {
///     'colorA': colorNodeA,
///     'colorB': colorNodeB,
///     'factor': factorNode,
///   }
/// );
/// ```
class CodeNode extends Node {
  /// The raw GLSL code to embed
  final String code;
  
  /// Map of placeholder names to nodes that provide their values
  final Map<String, Node>? includes;
  
  CodeNode(this.code, {this.includes}) {
    nodeType = 'CodeNode';
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
    String result = code;
    
    // Replace placeholders with node values
    if (includes != null) {
      includes!.forEach((key, node) {
        String value = node.build(builder, 'auto');
        // Replace ${key} with the node's generated code
        result = result.replaceAll('\${$key}', value);
      });
    }
    
    return result;
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['code'] = code;
    
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
