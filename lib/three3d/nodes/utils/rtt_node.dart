import 'package:three_dart_v2/three3d/renderers/index.dart';
import '../core/node.dart';
import '../core/node_builder.dart';

/// Node that implements Render-To-Texture (RTT) functionality.
/// 
/// Renders a scene to a texture that can be used in subsequent
/// rendering passes. Useful for post-processing effects, mirrors,
/// portals, or multi-pass rendering techniques.
/// 
/// Example:
/// ```dart
/// // Render scene to texture
/// var rttNode = RTTNode(
///   renderTarget: myRenderTarget,
///   uvNode: uvNode,
/// );
/// 
/// // Use in material
/// material.colorNode = rttNode;
/// ```
class RTTNode extends Node {
  /// Render target to sample from
  final WebGLRenderTarget? renderTarget;
  
  /// UV coordinates for sampling
  final Node uvNode;
  
  /// Texture attachment index (for MRT)
  final int attachmentIndex;
  
  /// Mipmap level to sample
  final Node? levelNode;
  
  RTTNode({
    this.renderTarget,
    required this.uvNode,
    this.attachmentIndex = 0,
    this.levelNode,
  }) {
    nodeType = 'RTTNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    uvNode.build(builder, 'vec2');
    levelNode?.build(builder, 'float');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    // Get texture from render target
    String textureSampler = builder.getUniformFromNode(this, 'sampler2D');
    
    // Get UV coordinates
    String uv = uvNode.build(builder, 'vec2');
    
    // Sample texture
    if (levelNode != null) {
      String level = levelNode!.build(builder, 'float');
      return 'textureLod($textureSampler, $uv, $level)';
    } else {
      return 'texture($textureSampler, $uv)';
    }
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['uvNode'] = uvNode.toJSON();
    json['attachmentIndex'] = attachmentIndex;
    if (levelNode != null) {
      json['levelNode'] = levelNode!.toJSON();
    }
    return json;
  }
  
  /// Create an RTTNode from JSON
  static RTTNode? fromJSON(Map<String, dynamic> json) {
    Node? uvNode = Node.fromJSON(json['uvNode']);
    if (uvNode == null) return null;
    
    int attachmentIndex = json['attachmentIndex'] ?? 0;
    Node? levelNode = json['levelNode'] != null 
      ? Node.fromJSON(json['levelNode']) 
      : null;
    
    return RTTNode(
      uvNode: uvNode,
      attachmentIndex: attachmentIndex,
      levelNode: levelNode,
    );
  }
}

/// Node that implements screen-space texture sampling.
/// 
/// Samples from the current framebuffer using screen-space coordinates.
/// Useful for screen-space effects like distortion, blur, or
/// post-processing.
/// 
/// Example:
/// ```dart
/// // Sample from screen
/// var screenNode = ScreenTextureNode(
///   uvNode: screenUVNode,
/// );
/// 
/// // With distortion
/// var distortedUV = uvNode.add(distortionNode);
/// var screenNode = ScreenTextureNode(
///   uvNode: distortedUV,
/// );
/// ```
class ScreenTextureNode extends Node {
  /// UV coordinates for sampling (screen space)
  final Node uvNode;
  
  /// Mipmap level to sample
  final Node? levelNode;
  
  ScreenTextureNode({
    required this.uvNode,
    this.levelNode,
  }) {
    nodeType = 'ScreenTextureNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    uvNode.build(builder, 'vec2');
    levelNode?.build(builder, 'float');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    // Get screen texture uniform
    String textureSampler = builder.getUniformFromNode(this, 'sampler2D');
    
    // Get UV coordinates
    String uv = uvNode.build(builder, 'vec2');
    
    // Sample texture
    if (levelNode != null) {
      String level = levelNode!.build(builder, 'float');
      return 'textureLod($textureSampler, $uv, $level)';
    } else {
      return 'texture($textureSampler, $uv)';
    }
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['uvNode'] = uvNode.toJSON();
    if (levelNode != null) {
      json['levelNode'] = levelNode!.toJSON();
    }
    return json;
  }
  
  /// Create a ScreenTextureNode from JSON
  static ScreenTextureNode? fromJSON(Map<String, dynamic> json) {
    Node? uvNode = Node.fromJSON(json['uvNode']);
    if (uvNode == null) return null;
    
    Node? levelNode = json['levelNode'] != null 
      ? Node.fromJSON(json['levelNode']) 
      : null;
    
    return ScreenTextureNode(
      uvNode: uvNode,
      levelNode: levelNode,
    );
  }
}

/// Node that provides screen-space UV coordinates.
/// 
/// Converts fragment coordinates to normalized screen-space UVs.
/// 
/// Example:
/// ```dart
/// // Get screen UV
/// var screenUV = ScreenUVNode();
/// 
/// // Use for screen-space effects
/// var screenColor = ScreenTextureNode(uvNode: screenUV);
/// ```
class ScreenUVNode extends Node {
  ScreenUVNode() {
    nodeType = 'ScreenUVNode';
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    // Generate screen-space UV from fragment coordinates
    return 'gl_FragCoord.xy / resolution.xy';
  }
  
  /// Create a ScreenUVNode from JSON
  static ScreenUVNode fromJSON(Map<String, dynamic> json) {
    return ScreenUVNode();
  }
}

/// Node that implements depth buffer sampling.
/// 
/// Samples from the depth buffer for depth-based effects.
/// 
/// Example:
/// ```dart
/// // Sample depth
/// var depthNode = DepthTextureNode(
///   uvNode: screenUVNode,
/// );
/// 
/// // Use for depth-based effects
/// var fog = depthNode.mul(fogDensity);
/// ```
class DepthTextureNode extends Node {
  /// UV coordinates for sampling
  final Node uvNode;
  
  /// Whether to linearize depth
  final bool linearize;
  
  DepthTextureNode({
    required this.uvNode,
    this.linearize = false,
  }) {
    nodeType = 'DepthTextureNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    uvNode.build(builder, 'vec2');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    // Get depth texture uniform
    String textureSampler = builder.getUniformFromNode(this, 'sampler2D');
    
    // Get UV coordinates
    String uv = uvNode.build(builder, 'vec2');
    
    // Sample depth
    String depth = 'texture($textureSampler, $uv).r';
    
    // Linearize if requested
    if (linearize) {
      return '''
        (function() {
          float d = $depth;
          float near = cameraNear;
          float far = cameraFar;
          return (2.0 * near) / (far + near - d * (far - near));
        })()
      ''';
    }
    
    return depth;
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['uvNode'] = uvNode.toJSON();
    json['linearize'] = linearize;
    return json;
  }
  
  /// Create a DepthTextureNode from JSON
  static DepthTextureNode? fromJSON(Map<String, dynamic> json) {
    Node? uvNode = Node.fromJSON(json['uvNode']);
    if (uvNode == null) return null;
    
    bool linearize = json['linearize'] ?? false;
    
    return DepthTextureNode(
      uvNode: uvNode,
      linearize: linearize,
    );
  }
}

// ============================================================================
// Convenience Functions
// ============================================================================

/// Sample from render target
RTTNode rtt({
  WebGLRenderTarget? renderTarget,
  required Node uvNode,
  int attachmentIndex = 0,
  Node? levelNode,
}) => RTTNode(
  renderTarget: renderTarget,
  uvNode: uvNode,
  attachmentIndex: attachmentIndex,
  levelNode: levelNode,
);

/// Sample from screen texture
ScreenTextureNode screenTexture({
  required Node uvNode,
  Node? levelNode,
}) => ScreenTextureNode(
  uvNode: uvNode,
  levelNode: levelNode,
);

/// Get screen-space UV coordinates
ScreenUVNode screenUV() => ScreenUVNode();

/// Sample from depth buffer
DepthTextureNode depthTexture({
  required Node uvNode,
  bool linearize = false,
}) => DepthTextureNode(
  uvNode: uvNode,
  linearize: linearize,
);
