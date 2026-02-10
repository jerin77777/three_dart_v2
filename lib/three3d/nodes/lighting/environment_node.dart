import '../core/node.dart';
import '../core/node_builder.dart';
import '../accessors/cube_texture_node.dart';
import '../../textures/cube_texture.dart';

/// Node that provides environment map lighting.
/// 
/// Environment nodes sample cube maps or equirectangular textures
/// to provide reflection and refraction effects based on view direction.
class EnvironmentNode extends Node {
  /// Environment cube texture
  final CubeTexture? cubeTexture;
  
  /// Reflection/refraction direction node
  final Node directionNode;
  
  /// Roughness node for mip level selection (optional)
  final Node? roughnessNode;
  
  /// Maximum mip level for roughness-based sampling
  final int maxMipLevel;
  
  /// Intensity multiplier
  final double intensity;
  
  EnvironmentNode({
    this.cubeTexture,
    required this.directionNode,
    this.roughnessNode,
    this.maxMipLevel = 5,
    this.intensity = 1.0,
  }) {
    nodeType = 'EnvironmentNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    // Analyze direction node
    directionNode.build(builder, 'vec3');
    
    // Analyze roughness node if provided
    roughnessNode?.build(builder, 'float');
    
    // Register environment map uniform
    if (cubeTexture != null) {
      builder.addUniform('environmentMap', 'samplerCube');
      builder.addUniform('environmentIntensity', 'float');
    }
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    if (cubeTexture == null) {
      // No environment map, return black
      return 'vec3(0.0)';
    }
    
    String direction = directionNode.build(builder, 'vec3');
    
    if (roughnessNode != null) {
      // Sample with roughness-based mip level
      String roughness = roughnessNode!.build(builder, 'float');
      String lod = '$roughness * ${_formatFloat(maxMipLevel.toDouble())}';
      
      String envMapUniform = builder.getUniformFromNode(
        this, 'samplerCube', 'environmentMap'
      );
      
      String sample = 'textureLod($envMapUniform, $direction, $lod).rgb';
      
      if (intensity != 1.0) {
        String intensityUniform = builder.getUniformFromNode(
          this, 'float', 'environmentIntensity'
        );
        return '$sample * $intensityUniform';
      }
      
      return sample;
    } else {
      // Sample without mip level
      CubeTextureNode cubeNode = CubeTextureNode(
        cubeTexture!,
        directionNode,
      );
      
      String sample = cubeNode.build(builder, 'vec4');
      
      if (intensity != 1.0) {
        String intensityUniform = builder.getUniformFromNode(
          this, 'float', 'environmentIntensity'
        );
        return '$sample.rgb * $intensityUniform';
      }
      
      return '$sample.rgb';
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
    json['directionNode'] = directionNode.toJSON();
    json['maxMipLevel'] = maxMipLevel;
    json['intensity'] = intensity;
    if (roughnessNode != null) {
      json['roughnessNode'] = roughnessNode!.toJSON();
    }
    return json;
  }
}
