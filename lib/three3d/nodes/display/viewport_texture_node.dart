import 'package:three_dart_v2/three3d/textures/index.dart';
import 'package:three_dart_v2/three3d/nodes/core/node.dart';
import 'package:three_dart_v2/three3d/nodes/core/node_builder.dart';

/// Node that samples from the viewport/screen texture.
/// 
/// ViewportTextureNode provides access to the current viewport contents,
/// enabling effects like refraction, reflection, and post-processing that
/// require reading from the rendered scene.
/// 
/// This is commonly used for:
/// - Screen-space reflections
/// - Refraction effects
/// - Post-processing effects
/// - UI overlays that sample the scene
/// 
/// Example:
/// ```dart
/// // Sample viewport at screen coordinates
/// Node screenUV = ScreenNode();
/// ViewportTextureNode viewportSample = ViewportTextureNode(
///   screenUV,
///   levelNode: FloatNode(0.0)
/// );
/// ```
class ViewportTextureNode extends Node {
  /// Node providing UV coordinates for sampling (should output vec2)
  final Node uvNode;
  
  /// Optional mipmap level node (should output float)
  final Node? levelNode;
  
  /// Optional viewport texture to sample from
  final Texture? viewportTexture;
  
  /// Create a viewport texture sampling node
  /// 
  /// [uvNode] - Node providing UV coordinates (typically screen coordinates)
  /// [levelNode] - Optional mipmap level for sampling
  /// [viewportTexture] - Optional specific viewport texture (uses default if not provided)
  ViewportTextureNode(
    this.uvNode, {
    this.levelNode,
    this.viewportTexture,
  }) {
    nodeType = 'ViewportTextureNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    super.analyze(builder);
    
    // Build dependencies
    uvNode.build(builder, 'vec2');
    levelNode?.build(builder, 'float');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    // Get uniform for the viewport texture
    String textureVar = builder.getUniformFromNode(this, 'sampler2D');
    
    // Get UV coordinates
    String uvVar = uvNode.build(builder, 'vec2');
    
    // Generate texture sampling code
    if (levelNode != null) {
      // Use textureLod for explicit mipmap level
      String levelVar = levelNode!.build(builder, 'float');
      return 'textureLod($textureVar, $uvVar, $levelVar)';
    } else {
      // Use standard texture sampling
      return 'texture($textureVar, $uvVar)';
    }
  }
  
  @override
  Node? getHash(NodeBuilder builder) {
    // Include viewport texture in hash
    return this;
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['uvNode'] = uvNode.toJSON();
    if (levelNode != null) {
      json['levelNode'] = levelNode!.toJSON();
    }
    if (viewportTexture != null) {
      json['viewportTextureUuid'] = viewportTexture!.uuid;
    }
    return json;
  }
}
