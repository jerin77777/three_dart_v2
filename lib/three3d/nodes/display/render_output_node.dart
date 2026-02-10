import 'package:three_dart_v2/three3d/nodes/core/node.dart';
import 'package:three_dart_v2/three3d/nodes/core/node_builder.dart';

/// Node that defines shader output.
/// 
/// RenderOutputNode specifies what value should be written to a render target
/// or output buffer. This is the final node in a fragment shader node graph.
/// 
/// Supports:
/// - Single render target output (gl_FragColor or fragColor)
/// - Multiple render target (MRT) outputs
/// - Custom output names for different rendering passes
/// 
/// Example:
/// ```dart
/// // Simple color output
/// Node finalColor = ColorNode(Color(0xFF0000));
/// RenderOutputNode output = RenderOutputNode(
///   finalColor,
///   outputName: 'fragColor'
/// );
/// 
/// // Multiple render targets
/// RenderOutputNode colorOutput = RenderOutputNode(
///   colorNode,
///   outputName: 'fragColor',
///   outputIndex: 0
/// );
/// RenderOutputNode normalOutput = RenderOutputNode(
///   normalNode,
///   outputName: 'fragNormal',
///   outputIndex: 1
/// );
/// ```
class RenderOutputNode extends Node {
  /// The node providing the output value
  final Node outputNode;
  
  /// The name of the output variable
  final String outputName;
  
  /// Optional output index for multiple render targets
  final int? outputIndex;
  
  /// The expected output type (vec4, vec3, etc.)
  final String outputType;
  
  /// Create a render output node
  /// 
  /// [outputNode] - Node providing the value to output
  /// [outputName] - Name of the output variable (e.g., 'fragColor', 'gl_FragColor')
  /// [outputIndex] - Optional index for MRT (multiple render targets)
  /// [outputType] - Expected output type (default: 'vec4')
  RenderOutputNode(
    this.outputNode, {
    this.outputName = 'fragColor',
    this.outputIndex,
    this.outputType = 'vec4',
  }) {
    nodeType = 'RenderOutputNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    super.analyze(builder);
    
    // Build output dependency
    outputNode.build(builder, outputType);
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    // Get the output value
    String value = outputNode.build(builder, outputType);
    
    // Generate output variable name
    String outputVar = _getOutputVariableName(builder);
    
    // Add output declaration if needed
    if (builder.shaderStage == 'fragment') {
      _declareOutput(builder, outputVar);
    }
    
    // Add assignment statement
    builder.addFlowCode('$outputVar = $value;');
    
    // Return empty string as this node generates statements, not expressions
    return '';
  }
  
  /// Get the output variable name based on GLSL version and MRT support
  String _getOutputVariableName(NodeBuilder builder) {
    if (outputIndex != null) {
      // Multiple render targets - use indexed output
      return '${outputName}_$outputIndex';
    } else {
      // Single output
      return outputName;
    }
  }
  
  /// Declare the output variable if needed
  void _declareOutput(NodeBuilder builder, String outputVar) {
    // Check if we need to declare the output
    // In GLSL 3.0+, we use 'out' variables
    // In older GLSL, gl_FragColor is built-in
    
    if (outputVar != 'gl_FragColor' && !builder.hasOutput(outputVar)) {
      if (outputIndex != null) {
        // MRT output with location
        builder.addOutput('layout(location = $outputIndex) out $outputType $outputVar;');
      } else {
        // Single output
        builder.addOutput('out $outputType $outputVar;');
      }
    }
  }
  
  @override
  Node? getHash(NodeBuilder builder) {
    // Include output configuration in hash
    return this;
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['outputNode'] = outputNode.toJSON();
    json['outputName'] = outputName;
    if (outputIndex != null) {
      json['outputIndex'] = outputIndex;
    }
    json['outputType'] = outputType;
    return json;
  }
}

/// Convenience function to create a color output node
RenderOutputNode colorOutput(Node colorNode, {int? index}) {
  return RenderOutputNode(
    colorNode,
    outputName: 'fragColor',
    outputIndex: index,
    outputType: 'vec4',
  );
}

/// Convenience function to create a normal output node (for MRT)
RenderOutputNode normalOutput(Node normalNode, {int? index}) {
  return RenderOutputNode(
    normalNode,
    outputName: 'fragNormal',
    outputIndex: index,
    outputType: 'vec4',
  );
}

/// Convenience function to create a position output node (for MRT)
RenderOutputNode positionOutput(Node positionNode, {int? index}) {
  return RenderOutputNode(
    positionNode,
    outputName: 'fragPosition',
    outputIndex: index,
    outputType: 'vec4',
  );
}

/// Convenience function to create a depth output node
RenderOutputNode depthOutput(Node depthNode) {
  return RenderOutputNode(
    depthNode,
    outputName: 'gl_FragDepth',
    outputType: 'float',
  );
}
