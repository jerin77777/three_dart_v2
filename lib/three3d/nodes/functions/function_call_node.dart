import '../core/node.dart';
import '../core/node_builder.dart';
import '../core/validation_error.dart';
import 'function_node.dart';

/// Node that invokes a defined function.
/// 
/// FunctionCallNode calls a function defined by FunctionNode, passing the
/// specified arguments. It validates that the argument types and counts match
/// the function's parameter requirements.
/// 
/// Example:
/// ```dart
/// FunctionCallNode call = FunctionCallNode(
///   functionNode: customLighting,
///   arguments: [normalNode, lightDirNode, lightColorNode],
/// );
/// ```
class FunctionCallNode extends Node {
  /// The function to call
  final FunctionNode functionNode;
  
  /// Arguments to pass to the function
  final List<Node> arguments;
  
  FunctionCallNode({
    required this.functionNode,
    required this.arguments,
  }) {
    nodeType = 'FunctionCallNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    // Validate parameter count and types
    _validateParameters(builder);
    
    // Ensure the function is declared
    functionNode.build(builder, 'auto');
    
    // Build all argument nodes
    for (int i = 0; i < arguments.length; i++) {
      String expectedType = i < functionNode.parameters.length
          ? functionNode.parameters[i].type
          : 'auto';
      arguments[i].build(builder, expectedType);
    }
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    // Ensure function is declared
    functionNode.build(builder, 'auto');
    
    // Build argument list
    List<String> argStrings = [];
    for (int i = 0; i < arguments.length; i++) {
      String expectedType = i < functionNode.parameters.length
          ? functionNode.parameters[i].type
          : 'auto';
      String argCode = arguments[i].build(builder, expectedType);
      argStrings.add(argCode);
    }
    
    // Generate function call
    return '${functionNode.name}(${argStrings.join(', ')})';
  }
  
  /// Validate that arguments match function parameters
  void _validateParameters(NodeBuilder builder) {
    List<FunctionParameter> params = functionNode.parameters;
    
    // Count required parameters
    int requiredCount = params.where((p) => p.required).length;
    int providedCount = arguments.length;
    
    // Check parameter count
    if (providedCount < requiredCount) {
      throw ValidationError(
        message: 'Function "${functionNode.name}" requires $requiredCount arguments but received $providedCount',
        node: this,
        nodeType: nodeType,
        severity: 'error',
      );
    }
    
    if (providedCount > params.length) {
      throw ValidationError(
        message: 'Function "${functionNode.name}" accepts at most ${params.length} arguments but received $providedCount',
        node: this,
        nodeType: nodeType,
        severity: 'error',
      );
    }
    
    // Validate argument types
    for (int i = 0; i < arguments.length; i++) {
      if (i < params.length) {
        String expectedType = params[i].type;
        String actualType = builder.getType(arguments[i]);
        
        // Check type compatibility
        if (!_isTypeCompatible(expectedType, actualType)) {
          throw ValidationError(
            message: 'Function "${functionNode.name}" parameter "${params[i].name}" expects type "$expectedType" but received "$actualType"',
            node: this,
            nodeType: nodeType,
            severity: 'error',
          );
        }
      }
    }
  }
  
  /// Check if two types are compatible
  bool _isTypeCompatible(String expected, String actual) {
    // Exact match
    if (expected == actual) return true;
    
    // Auto type matches anything
    if (expected == 'auto' || actual == 'auto') return true;
    
    // Numeric type conversions
    Set<String> numericTypes = {'float', 'int', 'uint'};
    if (numericTypes.contains(expected) && numericTypes.contains(actual)) {
      return true;
    }
    
    // Vector type conversions (same dimension)
    if (expected.startsWith('vec') && actual.startsWith('vec')) {
      String expectedDim = expected.substring(3);
      String actualDim = actual.substring(3);
      return expectedDim == actualDim;
    }
    
    if (expected.startsWith('ivec') && actual.startsWith('ivec')) {
      String expectedDim = expected.substring(4);
      String actualDim = actual.substring(4);
      return expectedDim == actualDim;
    }
    
    if (expected.startsWith('uvec') && actual.startsWith('uvec')) {
      String expectedDim = expected.substring(4);
      String actualDim = actual.substring(4);
      return expectedDim == actualDim;
    }
    
    // Matrix type conversions (same dimension)
    if (expected.startsWith('mat') && actual.startsWith('mat')) {
      return expected == actual;
    }
    
    // No conversion possible
    return false;
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['functionNode'] = functionNode.toJSON();
    json['arguments'] = arguments.map((arg) => arg.toJSON()).toList();
    return json;
  }
}
