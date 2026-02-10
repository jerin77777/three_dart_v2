import 'package:three_dart_v2/three3d/nodes/core/node.dart';
import 'package:three_dart_v2/three3d/nodes/core/node_builder.dart';

/// Node that applies tone mapping to HDR colors.
/// 
/// ToneMappingNode provides various tone mapping algorithms to convert
/// high dynamic range (HDR) colors to low dynamic range (LDR) for display.
/// This is essential for realistic rendering with HDR lighting.
/// 
/// Supported tone mapping types:
/// - 'linear': Simple exposure multiplication
/// - 'reinhard': Reinhard tone mapping
/// - 'cineon': Cineon/Filmic tone mapping
/// - 'aces': ACES Filmic tone mapping (Academy Color Encoding System)
/// - 'agx': AgX tone mapping
/// - 'neutral': Neutral tone mapping
/// 
/// Example:
/// ```dart
/// Node hdrColor = LightingNode(...);
/// Node exposure = FloatNode(1.0);
/// ToneMappingNode toneMapped = ToneMappingNode(
///   hdrColor,
///   toneMappingType: 'aces',
///   exposureNode: exposure
/// );
/// ```
class ToneMappingNode extends Node {
  /// The input HDR color node (should output vec3)
  final Node colorNode;
  
  /// The tone mapping algorithm to use
  final String toneMappingType;
  
  /// Optional exposure control node (should output float)
  final Node? exposureNode;
  
  /// Create a tone mapping node
  /// 
  /// [colorNode] - Node providing the HDR input color
  /// [toneMappingType] - The tone mapping algorithm ('linear', 'reinhard', 'cineon', 'aces', 'agx', 'neutral')
  /// [exposureNode] - Optional node for exposure control (defaults to 1.0)
  ToneMappingNode(
    this.colorNode, {
    required this.toneMappingType,
    this.exposureNode,
  }) {
    nodeType = 'ToneMappingNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    super.analyze(builder);
    
    // Build dependencies
    colorNode.build(builder, 'vec3');
    exposureNode?.build(builder, 'float');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    // Get the input color
    String color = colorNode.build(builder, 'vec3');
    
    // Get exposure value (default to 1.0 if not provided)
    String exposure = exposureNode?.build(builder, 'float') ?? '1.0';
    
    // Apply exposure
    String exposedColor = '($color * $exposure)';
    
    // Apply tone mapping based on type
    switch (toneMappingType.toLowerCase()) {
      case 'linear':
        return exposedColor;
        
      case 'reinhard':
        return _generateReinhardToneMapping(builder, exposedColor);
        
      case 'cineon':
        return _generateCineonToneMapping(builder, exposedColor);
        
      case 'aces':
        return _generateACESToneMapping(builder, exposedColor);
        
      case 'agx':
        return _generateAgXToneMapping(builder, exposedColor);
        
      case 'neutral':
        return _generateNeutralToneMapping(builder, exposedColor);
        
      default:
        // Unknown tone mapping type - return linear
        builder.addFlowCode('// Warning: Unknown tone mapping type "$toneMappingType", using linear');
        return exposedColor;
    }
  }
  
  /// Generate Reinhard tone mapping code
  String _generateReinhardToneMapping(NodeBuilder builder, String color) {
    if (!builder.hasFunction('reinhardToneMapping')) {
      builder.addFunction('''
vec3 reinhardToneMapping(vec3 color) {
  return color / (color + vec3(1.0));
}
''');
    }
    
    return 'reinhardToneMapping($color)';
  }
  
  /// Generate Cineon/Filmic tone mapping code
  String _generateCineonToneMapping(NodeBuilder builder, String color) {
    if (!builder.hasFunction('cineonToneMapping')) {
      builder.addFunction('''
vec3 cineonToneMapping(vec3 color) {
  // Cineon/Filmic tone mapping
  color = max(vec3(0.0), color - 0.004);
  return pow((color * (6.2 * color + 0.5)) / (color * (6.2 * color + 1.7) + 0.06), vec3(2.2));
}
''');
    }
    
    return 'cineonToneMapping($color)';
  }
  
  /// Generate ACES Filmic tone mapping code
  String _generateACESToneMapping(NodeBuilder builder, String color) {
    if (!builder.hasFunction('ACESFilmicToneMapping')) {
      builder.addFunction('''
vec3 ACESFilmicToneMapping(vec3 color) {
  // ACES Filmic tone mapping curve
  // Narkowicz 2015, "ACES Filmic Tone Mapping Curve"
  const float a = 2.51;
  const float b = 0.03;
  const float c = 2.43;
  const float d = 0.59;
  const float e = 0.14;
  return clamp((color * (a * color + b)) / (color * (c * color + d) + e), 0.0, 1.0);
}
''');
    }
    
    return 'ACESFilmicToneMapping($color)';
  }
  
  /// Generate AgX tone mapping code
  String _generateAgXToneMapping(NodeBuilder builder, String color) {
    if (!builder.hasFunction('agxToneMapping')) {
      builder.addFunction('''
vec3 agxToneMapping(vec3 color) {
  // AgX tone mapping
  // https://iolite-engine.com/blog_posts/minimal_agx_implementation
  const mat3 agxMat = mat3(
    0.842479062253094, 0.0423282422610123, 0.0423756549057051,
    0.0784335999999992, 0.878468636469772, 0.0784336,
    0.0792237451477643, 0.0791661274605434, 0.879142973793104
  );
  
  const float minEv = -12.47393;
  const float maxEv = 4.026069;
  
  color = agxMat * color;
  color = clamp(log2(color), minEv, maxEv);
  color = (color - minEv) / (maxEv - minEv);
  
  // Apply sigmoid
  color = pow(color, vec3(2.2));
  
  const mat3 agxMatInv = mat3(
    1.19687900512017, -0.0528968517574562, -0.0529716355144438,
    -0.0980208811401368, 1.15190312990417, -0.0980434501171241,
    -0.0990297440797205, -0.0989611768448433, 1.15107367264116
  );
  
  return agxMatInv * color;
}
''');
    }
    
    return 'agxToneMapping($color)';
  }
  
  /// Generate Neutral tone mapping code
  String _generateNeutralToneMapping(NodeBuilder builder, String color) {
    if (!builder.hasFunction('neutralToneMapping')) {
      builder.addFunction('''
vec3 neutralToneMapping(vec3 color) {
  // Neutral tone mapping
  // Based on Khronos PBR Neutral tone mapper
  const float startCompression = 0.8 - 0.04;
  const float desaturation = 0.15;
  
  float x = min(color.r, min(color.g, color.b));
  float offset = x < 0.08 ? x - 6.25 * x * x : 0.04;
  color -= offset;
  
  float peak = max(color.r, max(color.g, color.b));
  if (peak < startCompression) return color;
  
  const float d = 1.0 - startCompression;
  float newPeak = 1.0 - d * d / (peak + d - startCompression);
  color *= newPeak / peak;
  
  float g = 1.0 - 1.0 / (desaturation * (peak - newPeak) + 1.0);
  return mix(color, vec3(newPeak), g);
}
''');
    }
    
    return 'neutralToneMapping($color)';
  }
  
  @override
  Node? getHash(NodeBuilder builder) {
    // Include tone mapping type in hash
    return this;
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['colorNode'] = colorNode.toJSON();
    json['toneMappingType'] = toneMappingType;
    if (exposureNode != null) {
      json['exposureNode'] = exposureNode!.toJSON();
    }
    return json;
  }
}
