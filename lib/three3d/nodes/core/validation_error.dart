import 'node.dart';

/// Represents an error found during node graph validation.
/// 
/// Provides detailed information about what went wrong, where it occurred,
/// and suggestions for how to fix the issue.
class ValidationError {
  /// Human-readable error message
  final String message;
  
  /// The node where the error occurred (if applicable)
  final Node? node;
  
  /// Type of the node where the error occurred
  final String? nodeType;
  
  /// Line number in source code (for parsing errors)
  final int? lineNumber;
  
  /// Severity level: 'error' or 'warning'
  final String severity;
  
  /// Optional suggestion for fixing the error
  final String? suggestion;
  
  /// Additional context information
  final Map<String, dynamic>? context;
  
  ValidationError({
    required this.message,
    this.node,
    this.nodeType,
    this.lineNumber,
    this.severity = 'error',
    this.suggestion,
    this.context,
  });
  
  /// Create an error for type mismatch
  factory ValidationError.typeMismatch({
    required Node sourceNode,
    required String sourceType,
    required Node targetNode,
    required String targetType,
    String? inputName,
  }) {
    String inputInfo = inputName != null ? " input '$inputName'" : '';
    return ValidationError(
      message: 'Type mismatch: Cannot connect ${sourceNode.nodeType ?? 'Node'} '
               'output ($sourceType) to ${targetNode.nodeType ?? 'Node'}$inputInfo ($targetType)',
      node: targetNode,
      nodeType: targetNode.nodeType,
      severity: 'error',
      suggestion: _getTypeMismatchSuggestion(sourceType, targetType),
      context: {
        'sourceNode': sourceNode.uuid,
        'sourceType': sourceType,
        'targetNode': targetNode.uuid,
        'targetType': targetType,
        'inputName': inputName,
      },
    );
  }
  
  /// Create an error for circular dependency
  factory ValidationError.circularDependency({
    required List<Node> cycle,
  }) {
    String cycleDescription = cycle.map((n) => 
      '${n.nodeType ?? 'Node'}(${n.uuid.substring(0, 8)})'
    ).join(' → ');
    
    return ValidationError(
      message: 'Circular dependency detected in node graph',
      node: cycle.isNotEmpty ? cycle.first : null,
      nodeType: cycle.isNotEmpty ? cycle.first.nodeType : null,
      severity: 'error',
      suggestion: 'Remove one of the connections to break the cycle: $cycleDescription',
      context: {
        'cycle': cycle.map((n) => n.uuid).toList(),
        'cycleDescription': cycleDescription,
      },
    );
  }
  
  /// Create an error for missing required input
  factory ValidationError.missingInput({
    required Node node,
    required String inputName,
    required String inputType,
  }) {
    return ValidationError(
      message: 'Required input \'$inputName\' not connected on ${node.nodeType ?? 'Node'}',
      node: node,
      nodeType: node.nodeType,
      severity: 'error',
      suggestion: 'Connect a $inputType node to the \'$inputName\' input',
      context: {
        'inputName': inputName,
        'inputType': inputType,
      },
    );
  }
  
  /// Create an error for disconnected output
  factory ValidationError.disconnectedOutput({
    required Node node,
  }) {
    return ValidationError(
      message: 'Node ${node.nodeType ?? 'Node'} output is not connected to anything',
      node: node,
      nodeType: node.nodeType,
      severity: 'warning',
      suggestion: 'Connect this node to another node or remove it from the graph',
      context: {
        'nodeUuid': node.uuid,
      },
    );
  }
  
  /// Create an error for shader compilation failure
  factory ValidationError.shaderCompilation({
    required String error,
    Node? node,
    int? lineNumber,
  }) {
    return ValidationError(
      message: 'Shader compilation failed: $error',
      node: node,
      nodeType: node?.nodeType,
      lineNumber: lineNumber,
      severity: 'error',
      suggestion: 'Check the generated shader code for syntax errors',
      context: {
        'compilationError': error,
      },
    );
  }
  
  /// Create an error for unsupported feature
  factory ValidationError.unsupportedFeature({
    required String feature,
    required String platform,
    Node? node,
  }) {
    return ValidationError(
      message: 'Feature \'$feature\' is not supported on platform \'$platform\'',
      node: node,
      nodeType: node?.nodeType,
      severity: 'error',
      suggestion: 'Use a fallback implementation or target a different platform',
      context: {
        'feature': feature,
        'platform': platform,
      },
    );
  }
  
  /// Get a suggestion for fixing a type mismatch
  static String _getTypeMismatchSuggestion(String sourceType, String targetType) {
    // Vector to scalar
    if (_isVectorType(sourceType) && _isScalarType(targetType)) {
      return 'Use .x, .y, .z, or .w to extract a single component, or use a SplitNode';
    }
    
    // Scalar to vector
    if (_isScalarType(sourceType) && _isVectorType(targetType)) {
      return 'Use a ConvertNode or JoinNode to create a vector from scalar values';
    }
    
    // Different vector sizes
    if (_isVectorType(sourceType) && _isVectorType(targetType)) {
      int sourceSize = _getVectorSize(sourceType);
      int targetSize = _getVectorSize(targetType);
      
      if (sourceSize > targetSize) {
        return 'Use swizzling (e.g., .xy, .xyz) to extract the needed components';
      } else {
        return 'Use a JoinNode to combine with additional components';
      }
    }
    
    // Generic conversion
    return 'Use a ConvertNode to convert between types';
  }
  
  static bool _isVectorType(String type) {
    return type.startsWith('vec') || type.startsWith('ivec') || 
           type.startsWith('uvec') || type.startsWith('bvec');
  }
  
  static bool _isScalarType(String type) {
    return type == 'float' || type == 'int' || type == 'uint' || type == 'bool';
  }
  
  static int _getVectorSize(String type) {
    if (type.endsWith('2')) return 2;
    if (type.endsWith('3')) return 3;
    if (type.endsWith('4')) return 4;
    return 1;
  }
  
  /// Format this error as a string
  @override
  String toString() {
    StringBuffer buffer = StringBuffer();
    
    // Severity and message
    buffer.write('[$severity] $message');
    
    // Node information
    if (node != null) {
      buffer.write('\n  Node: ${nodeType ?? 'Unknown'}(uuid: ${node!.uuid.substring(0, 8)})');
    }
    
    // Line number (for parsing errors)
    if (lineNumber != null) {
      buffer.write('\n  Line: $lineNumber');
    }
    
    // Suggestion
    if (suggestion != null) {
      buffer.write('\n  Suggestion: $suggestion');
    }
    
    return buffer.toString();
  }
  
  /// Convert to JSON for serialization
  Map<String, dynamic> toJSON() {
    return {
      'message': message,
      'nodeUuid': node?.uuid,
      'nodeType': nodeType,
      'lineNumber': lineNumber,
      'severity': severity,
      'suggestion': suggestion,
      'context': context,
    };
  }
}

/// Exception thrown when node graph validation fails
class NodeValidationException implements Exception {
  final List<ValidationError> errors;
  
  NodeValidationException(this.errors);
  
  @override
  String toString() {
    StringBuffer buffer = StringBuffer();
    buffer.writeln('Node graph validation failed with ${errors.length} error(s):');
    
    for (int i = 0; i < errors.length; i++) {
      buffer.writeln('\n${i + 1}. ${errors[i]}');
    }
    
    return buffer.toString();
  }
}

/// Exception thrown when shader compilation fails
class ShaderCompilationException implements Exception {
  final String message;
  final Node? node;
  final String? shaderCode;
  
  ShaderCompilationException(this.message, {this.node, this.shaderCode});
  
  @override
  String toString() {
    StringBuffer buffer = StringBuffer();
    buffer.writeln('Shader compilation failed: $message');
    
    if (node != null) {
      buffer.writeln('Node: ${node!.nodeType ?? 'Unknown'}(${node!.uuid.substring(0, 8)})');
    }
    
    if (shaderCode != null) {
      buffer.writeln('\nGenerated shader code:');
      buffer.writeln(shaderCode);
    }
    
    return buffer.toString();
  }
}
