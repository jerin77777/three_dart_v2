import '../core/node.dart';
import '../core/node_builder.dart';
import '../accessors/texture_node.dart';
import '../../textures/texture.dart';

/// Node that provides ambient occlusion.
/// 
/// Ambient occlusion (AO) darkens areas where ambient light would be
/// occluded by nearby geometry, adding depth and realism to scenes.
/// Can use either a texture map or screen-space AO (SSAO).
class AONode extends Node {
  /// Ambient occlusion texture (if using texture-based AO)
  final Texture? aoTexture;
  
  /// UV coordinates node for texture sampling
  final Node? uvNode;
  
  /// AO intensity multiplier
  final double intensity;
  
  /// Whether to use screen-space AO instead of texture
  final bool useSSAO;
  
  AONode({
    this.aoTexture,
    this.uvNode,
    this.intensity = 1.0,
    this.useSSAO = false,
  }) {
    nodeType = 'AONode';
    
    if (!useSSAO && aoTexture == null) {
      throw ArgumentError('AONode requires either aoTexture or useSSAO=true');
    }
    
    if (aoTexture != null && uvNode == null) {
      throw ArgumentError('AONode with texture requires uvNode');
    }
  }
  
  @override
  void analyze(NodeBuilder builder) {
    if (useSSAO) {
      // Register SSAO uniforms
      builder.addUniform('ssaoTexture', 'sampler2D');
      builder.addUniform('ssaoIntensity', 'float');
    } else if (aoTexture != null) {
      // Analyze texture node
      uvNode!.build(builder, 'vec2');
    }
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    if (useSSAO) {
      // Use screen-space AO from a post-processing pass
      String ssaoTextureUniform = builder.getUniformFromNode(
        this, 'sampler2D', 'ssaoTexture'
      );
      String intensityUniform = builder.getUniformFromNode(
        this, 'float', 'ssaoIntensity'
      );
      
      // Sample SSAO texture using screen coordinates
      return '''
        texture($ssaoTextureUniform, gl_FragCoord.xy / vec2(textureSize($ssaoTextureUniform, 0))).r * $intensityUniform
      ''';
    } else {
      // Use texture-based AO
      TextureNode textureNode = TextureNode(
        aoTexture!,
        uvNode!,
      );
      
      String aoSample = textureNode.build(builder, 'vec4');
      
      // Extract red channel and apply intensity
      if (intensity != 1.0) {
        return 'mix(1.0, $aoSample.r, ${_formatFloat(intensity)})';
      } else {
        return '$aoSample.r';
      }
    }
  }
  
  String _formatFloat(double value) {
    if (value == value.toInt()) {
      return '${value.toInt()}.0';
    }
    return value.toString();
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['intensity'] = intensity;
    json['useSSAO'] = useSSAO;
    if (uvNode != null) {
      json['uvNode'] = uvNode!.toJSON();
    }
    return json;
  }
}
