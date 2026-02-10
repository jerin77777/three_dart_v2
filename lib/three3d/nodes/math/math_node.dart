import '../core/node.dart';
import '../core/node_builder.dart';

/// Node that performs mathematical operations.
/// 
/// Supports standard mathematical functions like sin, cos, abs, sqrt, etc.
/// Can take 1-3 input nodes depending on the operation.
/// 
/// Example:
/// ```dart
/// // Single parameter: sin(x)
/// var sinNode = MathNode('sin', xNode);
/// 
/// // Two parameters: pow(x, y)
/// var powNode = MathNode('pow', xNode, yNode);
/// 
/// // Three parameters: clamp(x, min, max)
/// var clampNode = MathNode('clamp', xNode, minNode, maxNode);
/// ```
class MathNode extends Node {
  /// The mathematical operation to perform
  final String method;
  
  /// First input node (required)
  final Node aNode;
  
  /// Second input node (optional, for binary operations)
  final Node? bNode;
  
  /// Third input node (optional, for ternary operations)
  final Node? cNode;
  
  /// Supported unary operations (single parameter)
  static const Set<String> unaryOps = {
    // Trigonometric
    'sin', 'cos', 'tan',
    'asin', 'acos', 'atan',
    'sinh', 'cosh', 'tanh',
    'asinh', 'acosh', 'atanh',
    
    // Exponential and logarithmic
    'exp', 'exp2', 'log', 'log2',
    'sqrt', 'inversesqrt',
    
    // Common
    'abs', 'sign', 'floor', 'ceil', 'fract',
    'round', 'trunc',
    
    // Angle and trigonometry
    'radians', 'degrees',
    
    // Vector
    'length', 'normalize',
    
    // Other
    'saturate', 'negate', 'oneMinus',
  };
  
  /// Supported binary operations (two parameters)
  static const Set<String> binaryOps = {
    // Arithmetic
    'pow', 'min', 'max', 'mod',
    
    // Geometric
    'dot', 'cross', 'distance', 'reflect',
    
    // Common
    'step', 'atan2',
    
    // Comparison
    'equal', 'notEqual', 'lessThan', 'lessThanEqual',
    'greaterThan', 'greaterThanEqual',
  };
  
  /// Supported ternary operations (three parameters)
  static const Set<String> ternaryOps = {
    'mix', 'clamp', 'smoothstep', 'faceforward', 'refract',
  };
  
  MathNode(this.method, this.aNode, [this.bNode, this.cNode]) {
    nodeType = 'MathNode';
    
    // Validate operation
    _validateOperation();
  }
  
  /// Validate that the operation is supported and has the correct number of parameters
  void _validateOperation() {
    if (bNode == null && cNode == null) {
      // Unary operation
      if (!unaryOps.contains(method)) {
        throw ArgumentError(
          'Unknown unary math operation: $method. '
          'Supported operations: ${unaryOps.join(', ')}'
        );
      }
    } else if (cNode == null) {
      // Binary operation
      if (!binaryOps.contains(method)) {
        throw ArgumentError(
          'Unknown binary math operation: $method. '
          'Supported operations: ${binaryOps.join(', ')}'
        );
      }
    } else {
      // Ternary operation
      if (!ternaryOps.contains(method)) {
        throw ArgumentError(
          'Unknown ternary math operation: $method. '
          'Supported operations: ${ternaryOps.join(', ')}'
        );
      }
    }
  }
  
  @override
  void analyze(NodeBuilder builder) {
    // Build dependencies
    aNode.build(builder, 'auto');
    bNode?.build(builder, 'auto');
    cNode?.build(builder, 'auto');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    String a = aNode.build(builder, output);
    
    // Handle special cases that need custom GLSL
    switch (method) {
      case 'saturate':
        return 'clamp($a, 0.0, 1.0)';
      
      case 'negate':
        return '(-$a)';
      
      case 'oneMinus':
        return '(1.0 - $a)';
      
      case 'atan2':
        // atan2 in GLSL is atan(y, x)
        if (bNode != null) {
          String b = bNode!.build(builder, output);
          return 'atan($a, $b)';
        }
        break;
    }
    
    // Standard function call format
    if (bNode == null) {
      // Unary operation
      return '$method($a)';
    }
    
    String b = bNode!.build(builder, output);
    
    if (cNode == null) {
      // Binary operation
      return '$method($a, $b)';
    }
    
    // Ternary operation
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
  
  /// Create a MathNode from JSON
  static MathNode? fromJSON(Map<String, dynamic> json) {
    String? method = json['method'];
    if (method == null) return null;
    
    Node? aNode = Node.fromJSON(json['aNode']);
    if (aNode == null) return null;
    
    Node? bNode = json['bNode'] != null ? Node.fromJSON(json['bNode']) : null;
    Node? cNode = json['cNode'] != null ? Node.fromJSON(json['cNode']) : null;
    
    return MathNode(method, aNode, bNode, cNode);
  }
}

// ============================================================================
// Convenience Functions
// ============================================================================

/// Create a sine node
MathNode sin(Node node) => MathNode('sin', node);

/// Create a cosine node
MathNode cos(Node node) => MathNode('cos', node);

/// Create a tangent node
MathNode tan(Node node) => MathNode('tan', node);

/// Create an arcsine node
MathNode asin(Node node) => MathNode('asin', node);

/// Create an arccosine node
MathNode acos(Node node) => MathNode('acos', node);

/// Create an arctangent node
MathNode atan(Node node) => MathNode('atan', node);

/// Create an arctangent2 node (atan2)
MathNode atan2(Node y, Node x) => MathNode('atan2', y, x);

/// Create an exponential node
MathNode exp(Node node) => MathNode('exp', node);

/// Create a base-2 exponential node
MathNode exp2(Node node) => MathNode('exp2', node);

/// Create a natural logarithm node
MathNode log(Node node) => MathNode('log', node);

/// Create a base-2 logarithm node
MathNode log2(Node node) => MathNode('log2', node);

/// Create a square root node
MathNode sqrt(Node node) => MathNode('sqrt', node);

/// Create an inverse square root node
MathNode inversesqrt(Node node) => MathNode('inversesqrt', node);

/// Create an absolute value node
MathNode abs(Node node) => MathNode('abs', node);

/// Create a sign node
MathNode sign(Node node) => MathNode('sign', node);

/// Create a floor node
MathNode floor(Node node) => MathNode('floor', node);

/// Create a ceiling node
MathNode ceil(Node node) => MathNode('ceil', node);

/// Create a fractional part node
MathNode fract(Node node) => MathNode('fract', node);

/// Create a round node
MathNode round(Node node) => MathNode('round', node);

/// Create a truncate node
MathNode trunc(Node node) => MathNode('trunc', node);

/// Create a radians conversion node
MathNode radians(Node node) => MathNode('radians', node);

/// Create a degrees conversion node
MathNode degrees(Node node) => MathNode('degrees', node);

/// Create a length node (vector length)
MathNode length(Node node) => MathNode('length', node);

/// Create a normalize node (normalize vector)
MathNode normalize(Node node) => MathNode('normalize', node);

/// Create a saturate node (clamp to 0-1)
MathNode saturate(Node node) => MathNode('saturate', node);

/// Create a negate node
MathNode negate(Node node) => MathNode('negate', node);

/// Create a one-minus node (1.0 - x)
MathNode oneMinus(Node node) => MathNode('oneMinus', node);

/// Create a power node
MathNode pow(Node base, Node exponent) => MathNode('pow', base, exponent);

/// Create a minimum node
MathNode min(Node a, Node b) => MathNode('min', a, b);

/// Create a maximum node
MathNode max(Node a, Node b) => MathNode('max', a, b);

/// Create a modulo node
MathNode mod(Node a, Node b) => MathNode('mod', a, b);

/// Create a dot product node
MathNode dot(Node a, Node b) => MathNode('dot', a, b);

/// Create a cross product node
MathNode cross(Node a, Node b) => MathNode('cross', a, b);

/// Create a distance node
MathNode distance(Node a, Node b) => MathNode('distance', a, b);

/// Create a reflect node
MathNode reflect(Node incident, Node normal) => MathNode('reflect', incident, normal);

/// Create a step node
MathNode step(Node edge, Node x) => MathNode('step', edge, x);

/// Create a mix (linear interpolation) node
MathNode mix(Node a, Node b, Node t) => MathNode('mix', a, b, t);

/// Create a clamp node
MathNode clamp(Node value, Node minVal, Node maxVal) => MathNode('clamp', value, minVal, maxVal);

/// Create a smoothstep node
MathNode smoothstep(Node edge0, Node edge1, Node x) => MathNode('smoothstep', edge0, edge1, x);

/// Create a faceforward node
MathNode faceforward(Node n, Node i, Node nref) => MathNode('faceforward', n, i, nref);

/// Create a refract node
MathNode refract(Node i, Node n, Node eta) => MathNode('refract', i, n, eta);
