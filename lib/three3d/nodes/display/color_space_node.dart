import 'package:three_dart_v2/three3d/nodes/core/node.dart';
import 'package:three_dart_v2/three3d/nodes/core/node_builder.dart';

/// Node that converts colors between different color spaces.
/// 
/// ColorSpaceNode provides color space conversion functionality, primarily
/// for converting between sRGB and linear color spaces. This is essential
/// for correct color handling in physically-based rendering.
/// 
/// Example:
/// ```dart
/// // Convert sRGB texture to linear space for lighting calculations
/// Node colorNode = ColorNode(Color(0xFF8080));
/// ColorSpaceNode linearNode = ColorSpaceNode(
///   colorNode,
///   sourceColorSpace: 'srgb',
///   targetColorSpace: 'linear'
/// );
/// ```
class ColorSpaceNode extends Node {
  /// The input color node (should output vec3 or vec4)
  final Node colorNode;
  
  /// Source color space ('srgb', 'linear', 'display-p3', etc.)
  final String sourceColorSpace;
  
  /// Target color space ('srgb', 'linear', 'display-p3', etc.)
  final String targetColorSpace;
  
  /// Create a color space conversion node
  /// 
  /// [colorNode] - Node providing the input color
  /// [sourceColorSpace] - The color space of the input
  /// [targetColorSpace] - The desired output color space
  ColorSpaceNode(
    this.colorNode, {
    required this.sourceColorSpace,
    required this.targetColorSpace,
  }) {
    nodeType = 'ColorSpaceNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    super.analyze(builder);
    
    // Build color dependency
    colorNode.build(builder, 'vec3');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    // Get the input color
    String color = colorNode.build(builder, 'vec3');
    
    // If source and target are the same, no conversion needed
    if (sourceColorSpace == targetColorSpace) {
      return color;
    }
    
    // Generate conversion code based on source and target
    if (sourceColorSpace == 'srgb' && targetColorSpace == 'linear') {
      return _generateSRGBToLinear(builder, color);
    } else if (sourceColorSpace == 'linear' && targetColorSpace == 'srgb') {
      return _generateLinearToSRGB(builder, color);
    } else if (sourceColorSpace == 'display-p3' && targetColorSpace == 'linear') {
      return _generateDisplayP3ToLinear(builder, color);
    } else if (sourceColorSpace == 'linear' && targetColorSpace == 'display-p3') {
      return _generateLinearToDisplayP3(builder, color);
    }
    
    // Unsupported conversion - return input unchanged with warning
    builder.addFlowCode('// Warning: Unsupported color space conversion from $sourceColorSpace to $targetColorSpace');
    return color;
  }
  
  /// Generate sRGB to linear conversion code
  String _generateSRGBToLinear(NodeBuilder builder, String color) {
    // Add conversion function if not already present
    if (!builder.hasFunction('sRGBToLinear')) {
      builder.addFunction('''
vec3 sRGBToLinear(vec3 srgb) {
  // Accurate sRGB to linear conversion
  vec3 linearLow = srgb / 12.92;
  vec3 linearHigh = pow((srgb + 0.055) / 1.055, vec3(2.4));
  return mix(linearLow, linearHigh, step(vec3(0.04045), srgb));
}
''');
    }
    
    return 'sRGBToLinear($color)';
  }
  
  /// Generate linear to sRGB conversion code
  String _generateLinearToSRGB(NodeBuilder builder, String color) {
    // Add conversion function if not already present
    if (!builder.hasFunction('linearToSRGB')) {
      builder.addFunction('''
vec3 linearToSRGB(vec3 linear) {
  // Accurate linear to sRGB conversion
  vec3 srgbLow = linear * 12.92;
  vec3 srgbHigh = 1.055 * pow(linear, vec3(1.0 / 2.4)) - 0.055;
  return mix(srgbLow, srgbHigh, step(vec3(0.0031308), linear));
}
''');
    }
    
    return 'linearToSRGB($color)';
  }
  
  /// Generate Display P3 to linear conversion code
  String _generateDisplayP3ToLinear(NodeBuilder builder, String color) {
    // Add conversion function if not already present
    if (!builder.hasFunction('displayP3ToLinear')) {
      builder.addFunction('''
vec3 displayP3ToLinear(vec3 displayP3) {
  // Display P3 uses same transfer function as sRGB
  vec3 linearLow = displayP3 / 12.92;
  vec3 linearHigh = pow((displayP3 + 0.055) / 1.055, vec3(2.4));
  vec3 linear = mix(linearLow, linearHigh, step(vec3(0.04045), displayP3));
  
  // Apply Display P3 to linear RGB color space conversion matrix
  mat3 displayP3ToLinearMatrix = mat3(
    0.8224621, 0.1775380, 0.0000000,
    0.0331941, 0.9668058, 0.0000000,
    0.0170827, 0.0723974, 0.9105199
  );
  
  return displayP3ToLinearMatrix * linear;
}
''');
    }
    
    return 'displayP3ToLinear($color)';
  }
  
  /// Generate linear to Display P3 conversion code
  String _generateLinearToDisplayP3(NodeBuilder builder, String color) {
    // Add conversion function if not already present
    if (!builder.hasFunction('linearToDisplayP3')) {
      builder.addFunction('''
vec3 linearToDisplayP3(vec3 linear) {
  // Apply linear RGB to Display P3 color space conversion matrix
  mat3 linearToDisplayP3Matrix = mat3(
    1.2249401, -0.2249404, 0.0000000,
    -0.0420569, 1.0420571, 0.0000000,
    -0.0196376, -0.0786361, 1.0982735
  );
  
  vec3 displayP3 = linearToDisplayP3Matrix * linear;
  
  // Apply Display P3 transfer function (same as sRGB)
  vec3 displayP3Low = displayP3 * 12.92;
  vec3 displayP3High = 1.055 * pow(displayP3, vec3(1.0 / 2.4)) - 0.055;
  return mix(displayP3Low, displayP3High, step(vec3(0.0031308), displayP3));
}
''');
    }
    
    return 'linearToDisplayP3($color)';
  }
  
  @override
  Node? getHash(NodeBuilder builder) {
    // Include color space parameters in hash
    return this;
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['colorNode'] = colorNode.toJSON();
    json['sourceColorSpace'] = sourceColorSpace;
    json['targetColorSpace'] = targetColorSpace;
    return json;
  }
}
