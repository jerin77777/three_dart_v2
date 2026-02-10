import 'package:three_dart_v2/three3d/textures/index.dart';
import 'package:three_dart_v2/three3d/nodes/core/node.dart';
import 'package:three_dart_v2/three3d/nodes/core/node_builder.dart';

/// Node that samples cube map textures.
/// 
/// CubeTextureNode provides cube map texture sampling functionality,
/// typically used for environment mapping, reflections, and skyboxes.
/// 
/// Example:
/// ```dart
/// CubeTexture envMap = CubeTexture();
/// Node directionNode = reflectNode; // vec3 direction
/// CubeTextureNode cubeNode = CubeTextureNode(envMap, directionNode);
/// ```
class CubeTextureNode extends Node {
  /// The cube texture to sample
  final CubeTexture texture;
  
  /// Node providing the sampling direction (vec3)
  final Node uvwNode;
  
  /// Optional node providing mipmap level (float)
  final Node? levelNode;
  
  /// Create a cube texture sampling node
  /// 
  /// [texture] - The cube texture to sample
  /// [uvwNode] - Node that provides the 3D direction vector (should output vec3)
  /// [levelNode] - Optional node for explicit mipmap level control
  CubeTextureNode(this.texture, this.uvwNode, {this.levelNode}) {
    nodeType = 'CubeTextureNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    super.analyze(builder);
    
    // Build dependencies
    uvwNode.build(builder, 'vec3');
    levelNode?.build(builder, 'float');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    // Get uniform for the cube texture
    String textureVar = builder.getUniformFromNode(this, 'samplerCube');
    
    // Get direction vector
    String uvwVar = uvwNode.build(builder, 'vec3');
    
    // Generate cube texture sampling code
    if (levelNode != null) {
      // Use textureLod for explicit mipmap level
      String levelVar = levelNode!.build(builder, 'float');
      return 'textureLod($textureVar, $uvwVar, $levelVar)';
    } else {
      // Use standard texture sampling
      return 'texture($textureVar, $uvwVar)';
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
    json['uvwNode'] = uvwNode.toJSON();
    if (levelNode != null) {
      json['levelNode'] = levelNode!.toJSON();
    }
    // Note: Texture serialization would need to be handled separately
    json['textureUuid'] = texture.uuid;
    return json;
  }
}

