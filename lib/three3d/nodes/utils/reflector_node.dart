import 'package:three_dart_v2/three3d/textures/index.dart';
import '../core/node.dart';
import '../core/node_builder.dart';

/// Node that implements reflection effects.
/// 
/// Samples a reflection texture using reflected view direction.
/// Useful for creating mirror surfaces, water reflections, or
/// environment reflections.
/// 
/// Example:
/// ```dart
/// // Basic reflection
/// var reflectionNode = ReflectorNode(
///   texture: reflectionTexture,
///   normal: normalNode,
/// );
/// 
/// // Reflection with custom view direction
/// var reflectionNode = ReflectorNode(
///   texture: reflectionTexture,
///   normal: normalNode,
///   viewDirection: customViewDir,
/// );
/// ```
class ReflectorNode extends Node {
  /// Reflection texture to sample
  final Texture? texture;
  
  /// Texture node (alternative to texture)
  final Node? textureNode;
  
  /// Surface normal for reflection calculation
  final Node normal;
  
  /// View direction (optional, uses default if not provided)
  final Node? viewDirection;
  
  /// Reflection intensity/strength
  final Node? intensity;
  
  ReflectorNode({
    this.texture,
    this.textureNode,
    required this.normal,
    this.viewDirection,
    this.intensity,
  }) {
    nodeType = 'ReflectorNode';
    
    if (texture == null && textureNode == null) {
      throw ArgumentError(
        'ReflectorNode requires either texture or textureNode'
      );
    }
  }
  
  @override
  void analyze(NodeBuilder builder) {
    normal.build(builder, 'vec3');
    viewDirection?.build(builder, 'vec3');
    intensity?.build(builder, 'float');
    textureNode?.build(builder, 'sampler2D');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    // Get or create texture uniform
    String textureSampler;
    if (textureNode != null) {
      textureSampler = textureNode!.build(builder, 'sampler2D');
    } else {
      textureSampler = builder.getUniformFromNode(this, 'sampler2D');
    }
    
    // Get normal
    String normalVar = normal.build(builder, 'vec3');
    
    // Get or compute view direction
    String viewDir;
    if (viewDirection != null) {
      viewDir = viewDirection!.build(builder, 'vec3');
    } else {
      // Use default view direction from camera
      viewDir = 'normalize(vViewPosition)';
    }
    
    // Calculate reflection direction
    String reflectDir = 'reflect($viewDir, normalize($normalVar))';
    
    // Convert reflection direction to UV coordinates
    // Using spherical mapping
    String reflectUV = '''
      (function() {
        vec3 r = $reflectDir;
        vec2 uv;
        uv.x = atan(r.z, r.x) / (2.0 * 3.14159265359) + 0.5;
        uv.y = asin(r.y) / 3.14159265359 + 0.5;
        return uv;
      })()
    ''';
    
    // Sample reflection texture
    String reflection = 'texture($textureSampler, $reflectUV)';
    
    // Apply intensity if provided
    if (intensity != null) {
      String intensityVar = intensity!.build(builder, 'float');
      return '($reflection * $intensityVar)';
    }
    
    return reflection;
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    if (textureNode != null) {
      json['textureNode'] = textureNode!.toJSON();
    }
    json['normal'] = normal.toJSON();
    if (viewDirection != null) {
      json['viewDirection'] = viewDirection!.toJSON();
    }
    if (intensity != null) {
      json['intensity'] = intensity!.toJSON();
    }
    return json;
  }
  
  /// Create a ReflectorNode from JSON
  static ReflectorNode? fromJSON(Map<String, dynamic> json) {
    Node? normal = Node.fromJSON(json['normal']);
    if (normal == null) return null;
    
    Node? textureNode = json['textureNode'] != null 
      ? Node.fromJSON(json['textureNode']) 
      : null;
    Node? viewDirection = json['viewDirection'] != null 
      ? Node.fromJSON(json['viewDirection']) 
      : null;
    Node? intensity = json['intensity'] != null 
      ? Node.fromJSON(json['intensity']) 
      : null;
    
    return ReflectorNode(
      textureNode: textureNode,
      normal: normal,
      viewDirection: viewDirection,
      intensity: intensity,
    );
  }
}

/// Node that implements refraction effects.
/// 
/// Samples a texture using refracted view direction based on
/// index of refraction. Useful for glass, water, or other
/// transparent materials.
/// 
/// Example:
/// ```dart
/// // Glass refraction
/// var refractionNode = RefractorNode(
///   texture: sceneTexture,
///   normal: normalNode,
///   ior: ConstantNode(1.5), // Glass IOR
/// );
/// ```
class RefractorNode extends Node {
  /// Texture to sample
  final Texture? texture;
  
  /// Texture node (alternative to texture)
  final Node? textureNode;
  
  /// Surface normal for refraction calculation
  final Node normal;
  
  /// Index of refraction (IOR)
  final Node ior;
  
  /// View direction (optional, uses default if not provided)
  final Node? viewDirection;
  
  RefractorNode({
    this.texture,
    this.textureNode,
    required this.normal,
    required this.ior,
    this.viewDirection,
  }) {
    nodeType = 'RefractorNode';
    
    if (texture == null && textureNode == null) {
      throw ArgumentError(
        'RefractorNode requires either texture or textureNode'
      );
    }
  }
  
  @override
  void analyze(NodeBuilder builder) {
    normal.build(builder, 'vec3');
    ior.build(builder, 'float');
    viewDirection?.build(builder, 'vec3');
    textureNode?.build(builder, 'sampler2D');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    // Get or create texture uniform
    String textureSampler;
    if (textureNode != null) {
      textureSampler = textureNode!.build(builder, 'sampler2D');
    } else {
      textureSampler = builder.getUniformFromNode(this, 'sampler2D');
    }
    
    // Get normal and IOR
    String normalVar = normal.build(builder, 'vec3');
    String iorVar = ior.build(builder, 'float');
    
    // Get or compute view direction
    String viewDir;
    if (viewDirection != null) {
      viewDir = viewDirection!.build(builder, 'vec3');
    } else {
      viewDir = 'normalize(vViewPosition)';
    }
    
    // Calculate refraction direction
    String refractDir = 'refract($viewDir, normalize($normalVar), 1.0 / $iorVar)';
    
    // Convert refraction direction to UV coordinates
    String refractUV = '''
      (function() {
        vec3 r = $refractDir;
        vec2 uv;
        uv.x = atan(r.z, r.x) / (2.0 * 3.14159265359) + 0.5;
        uv.y = asin(r.y) / 3.14159265359 + 0.5;
        return uv;
      })()
    ''';
    
    // Sample refraction texture
    return 'texture($textureSampler, $refractUV)';
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    if (textureNode != null) {
      json['textureNode'] = textureNode!.toJSON();
    }
    json['normal'] = normal.toJSON();
    json['ior'] = ior.toJSON();
    if (viewDirection != null) {
      json['viewDirection'] = viewDirection!.toJSON();
    }
    return json;
  }
  
  /// Create a RefractorNode from JSON
  static RefractorNode? fromJSON(Map<String, dynamic> json) {
    Node? normal = Node.fromJSON(json['normal']);
    Node? ior = Node.fromJSON(json['ior']);
    
    if (normal == null || ior == null) return null;
    
    Node? textureNode = json['textureNode'] != null 
      ? Node.fromJSON(json['textureNode']) 
      : null;
    Node? viewDirection = json['viewDirection'] != null 
      ? Node.fromJSON(json['viewDirection']) 
      : null;
    
    return RefractorNode(
      textureNode: textureNode,
      normal: normal,
      ior: ior,
      viewDirection: viewDirection,
    );
  }
}

// ============================================================================
// Convenience Functions
// ============================================================================

/// Create reflection effect
ReflectorNode reflect({
  Texture? texture,
  Node? textureNode,
  required Node normal,
  Node? viewDirection,
  Node? intensity,
}) => ReflectorNode(
  texture: texture,
  textureNode: textureNode,
  normal: normal,
  viewDirection: viewDirection,
  intensity: intensity,
);

/// Create refraction effect
RefractorNode refract({
  Texture? texture,
  Node? textureNode,
  required Node normal,
  required Node ior,
  Node? viewDirection,
}) => RefractorNode(
  texture: texture,
  textureNode: textureNode,
  normal: normal,
  ior: ior,
  viewDirection: viewDirection,
);
