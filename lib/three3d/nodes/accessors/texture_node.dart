import 'package:three_dart_v2/three3d/textures/index.dart';
import 'package:three_dart_v2/three3d/nodes/core/node.dart';
import 'package:three_dart_v2/three3d/nodes/core/node_builder.dart';

/// Node that samples 2D textures.
/// 
/// TextureNode provides texture sampling functionality with support for
/// UV coordinates and mipmap level control.
/// 
/// Example:
/// ```dart
/// Texture albedoTexture = Texture();
/// Node uvNode = BufferAttributeNode(geometry.getAttribute('uv'), 'uv');
/// TextureNode textureNode = TextureNode(albedoTexture, uvNode);
/// ```
class TextureNode extends Node {
  /// The texture to sample
  final Texture texture;
  
  /// Node providing UV coordinates (vec2)
  final Node uvNode;
  
  /// Optional node providing mipmap level (float)
  final Node? levelNode;
  
  /// Create a texture sampling node
  /// 
  /// [texture] - The 2D texture to sample
  /// [uvNode] - Node that provides UV coordinates (should output vec2)
  /// [levelNode] - Optional node for explicit mipmap level control
  TextureNode(this.texture, this.uvNode, {this.levelNode}) {
    nodeType = 'TextureNode';
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
    // Get uniform for the texture
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
    // Include texture properties in hash for caching
    return this;
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['uvNode'] = uvNode.toJSON();
    if (levelNode != null) {
      json['levelNode'] = levelNode!.toJSON();
    }
    // Note: Texture serialization would need to be handled separately
    json['textureUuid'] = texture.uuid;
    return json;
  }
}

