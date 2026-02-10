import '../core/node.dart';
import '../core/node_builder.dart';

/// Node that remaps a value from one range to another.
/// 
/// Performs linear interpolation to map values from an input range
/// to an output range. Useful for normalizing values, scaling, or
/// converting between different value spaces.
/// 
/// Formula: output = (value - inMin) / (inMax - inMin) * (outMax - outMin) + outMin
/// 
/// Example:
/// ```dart
/// // Remap from [0, 1] to [0, 10]
/// var remapNode = RemapNode(
///   value: inputNode,
///   inMin: ConstantNode(0),
///   inMax: ConstantNode(1),
///   outMin: ConstantNode(0),
///   outMax: ConstantNode(10),
/// );
/// 
/// // Remap from [-1, 1] to [0, 1] (normalize)
/// var normalizeNode = RemapNode(
///   value: inputNode,
///   inMin: ConstantNode(-1),
///   inMax: ConstantNode(1),
///   outMin: ConstantNode(0),
///   outMax: ConstantNode(1),
/// );
/// ```
class RemapNode extends Node {
  /// Value to remap
  final Node value;
  
  /// Minimum of input range
  final Node inMin;
  
  /// Maximum of input range
  final Node inMax;
  
  /// Minimum of output range
  final Node outMin;
  
  /// Maximum of output range
  final Node outMax;
  
  /// Whether to clamp the output to the output range
  final bool clamp;
  
  RemapNode({
    required this.value,
    required this.inMin,
    required this.inMax,
    required this.outMin,
    required this.outMax,
    this.clamp = false,
  }) {
    nodeType = 'RemapNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    value.build(builder, 'auto');
    inMin.build(builder, 'auto');
    inMax.build(builder, 'auto');
    outMin.build(builder, 'auto');
    outMax.build(builder, 'auto');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    String val = value.build(builder, output);
    String iMin = inMin.build(builder, output);
    String iMax = inMax.build(builder, output);
    String oMin = outMin.build(builder, output);
    String oMax = outMax.build(builder, output);
    
    // Generate remap expression
    String remapped = '(($val - $iMin) / ($iMax - $iMin) * ($oMax - $oMin) + $oMin)';
    
    // Apply clamping if requested
    if (clamp) {
      return 'clamp($remapped, min($oMin, $oMax), max($oMin, $oMax))';
    }
    
    return remapped;
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['value'] = value.toJSON();
    json['inMin'] = inMin.toJSON();
    json['inMax'] = inMax.toJSON();
    json['outMin'] = outMin.toJSON();
    json['outMax'] = outMax.toJSON();
    json['clamp'] = clamp;
    return json;
  }
  
  /// Create a RemapNode from JSON
  static RemapNode? fromJSON(Map<String, dynamic> json) {
    Node? value = Node.fromJSON(json['value']);
    Node? inMin = Node.fromJSON(json['inMin']);
    Node? inMax = Node.fromJSON(json['inMax']);
    Node? outMin = Node.fromJSON(json['outMin']);
    Node? outMax = Node.fromJSON(json['outMax']);
    
    if (value == null || inMin == null || inMax == null || 
        outMin == null || outMax == null) {
      return null;
    }
    
    bool clamp = json['clamp'] ?? false;
    
    return RemapNode(
      value: value,
      inMin: inMin,
      inMax: inMax,
      outMin: outMin,
      outMax: outMax,
      clamp: clamp,
    );
  }
}

/// Node that performs smoothstep interpolation.
/// 
/// Performs smooth Hermite interpolation between 0 and 1 when
/// value is between edge0 and edge1.
/// 
/// Example:
/// ```dart
/// // Smooth transition from 0 to 1 between edges
/// var smoothNode = SmoothstepNode(
///   edge0: ConstantNode(0.4),
///   edge1: ConstantNode(0.6),
///   value: inputNode,
/// );
/// ```
class SmoothstepNode extends Node {
  /// Lower edge of interpolation range
  final Node edge0;
  
  /// Upper edge of interpolation range
  final Node edge1;
  
  /// Value to interpolate
  final Node value;
  
  SmoothstepNode({
    required this.edge0,
    required this.edge1,
    required this.value,
  }) {
    nodeType = 'SmoothstepNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    edge0.build(builder, 'auto');
    edge1.build(builder, 'auto');
    value.build(builder, 'auto');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    String e0 = edge0.build(builder, output);
    String e1 = edge1.build(builder, output);
    String val = value.build(builder, output);
    
    return 'smoothstep($e0, $e1, $val)';
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['edge0'] = edge0.toJSON();
    json['edge1'] = edge1.toJSON();
    json['value'] = value.toJSON();
    return json;
  }
  
  /// Create a SmoothstepNode from JSON
  static SmoothstepNode? fromJSON(Map<String, dynamic> json) {
    Node? edge0 = Node.fromJSON(json['edge0']);
    Node? edge1 = Node.fromJSON(json['edge1']);
    Node? value = Node.fromJSON(json['value']);
    
    if (edge0 == null || edge1 == null || value == null) return null;
    
    return SmoothstepNode(
      edge0: edge0,
      edge1: edge1,
      value: value,
    );
  }
}

// ============================================================================
// Convenience Functions
// ============================================================================

/// Remap value from one range to another
RemapNode remap({
  required Node value,
  required Node inMin,
  required Node inMax,
  required Node outMin,
  required Node outMax,
  bool clamp = false,
}) => RemapNode(
  value: value,
  inMin: inMin,
  inMax: inMax,
  outMin: outMin,
  outMax: outMax,
  clamp: clamp,
);

/// Normalize value from [inMin, inMax] to [0, 1]
RemapNode normalize({
  required Node value,
  required Node inMin,
  required Node inMax,
  bool clamp = false,
}) => RemapNode(
  value: value,
  inMin: inMin,
  inMax: inMax,
  outMin: ConstantNode(0),
  outMax: ConstantNode(1),
  clamp: clamp,
);

/// Smoothstep interpolation
SmoothstepNode smoothstep({
  required Node edge0,
  required Node edge1,
  required Node value,
}) => SmoothstepNode(
  edge0: edge0,
  edge1: edge1,
  value: value,
);
