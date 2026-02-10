import '../core/node.dart';
import '../core/node_builder.dart';

/// Represents a parameter in a function definition.
class FunctionParameter {
  /// Parameter name
  final String name;
  
  /// Parameter type (e.g., 'float', 'vec3', 'sampler2D')
  final String type;
  
  /// Whether this parameter is required
  final bool required;
  
  /// Default value if parameter is optional
  final dynamic defaultValue;
  
  FunctionParameter({
    required this.name,
    required this.type,
    this.required = true,
    this.defaultValue,
  });
  
  Map<String, dynamic> toJSON() {
    return {
      'name': name,
      'type': type,
      'required': required,
      if (defaultValue != null) 'defaultValue': defaultValue,
    };
  }
}

/// Node that defines a reusable shader function.
/// 
/// FunctionNode allows developers to create custom GLSL functions that can be
/// called multiple times within a shader. The function is declared once and
/// can be invoked using FunctionCallNode.
/// 
/// Example:
/// ```dart
/// FunctionNode customLighting = FunctionNode(
///   name: 'calculateLighting',
///   parameters: [
///     FunctionParameter(name: 'normal', type: 'vec3'),
///     FunctionParameter(name: 'lightDir', type: 'vec3'),
///     FunctionParameter(name: 'lightColor', type: 'vec3'),
///   ],
///   returnType: 'vec3',
///   bodyNode: CodeNode('return lightColor * max(dot(normal, lightDir), 0.0);'),
/// );
/// ```
class FunctionNode extends Node {
  /// Function name (must be unique within the shader)
  final String name;
  
  /// List of function parameters
  final List<FunctionParameter> parameters;
  
  /// Return type of the function
  final String returnType;
  
  /// Node that generates the function body
  final Node bodyNode;
  
  /// Whether this function has been declared in the current shader
  bool _isDeclared = false;
  
  FunctionNode({
    required this.name,
    required this.parameters,
    required this.returnType,
    required this.bodyNode,
  }) {
    nodeType = 'FunctionNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    // Build the body node during analysis
    bodyNode.build(builder, returnType);
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    // Declare the function if not already declared
    if (!_isDeclared) {
      _declareFunction(builder);
      _isDeclared = true;
    }
    
    // Return the function name (for use in expressions)
    return name;
  }
  
  /// Declare the function in the shader
  void _declareFunction(NodeBuilder builder) {
    // Build parameter list
    String params = parameters.map((p) => '${p.type} ${p.name}').join(', ');
    
    // Start function declaration
    builder.addFunction('$returnType $name($params) {');
    
    // Generate function body
    String body = bodyNode.build(builder, returnType);
    
    // If the body is a simple expression, wrap it in a return statement
    if (!body.contains('return') && !body.contains(';')) {
      builder.addFunction('  return $body;');
    } else {
      // Body contains statements, add as-is
      for (String line in body.split('\n')) {
        if (line.trim().isNotEmpty) {
          builder.addFunction('  $line');
        }
      }
    }
    
    // End function declaration
    builder.addFunction('}');
    builder.addFunction(''); // Empty line for readability
  }
  
  /// Reset the declaration state (useful for rebuilding)
  @override
  void reset() {
    super.reset();
    _isDeclared = false;
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['name'] = name;
    json['parameters'] = parameters.map((p) => p.toJSON()).toList();
    json['returnType'] = returnType;
    json['bodyNode'] = bodyNode.toJSON();
    return json;
  }
}
