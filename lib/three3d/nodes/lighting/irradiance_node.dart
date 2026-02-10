import '../core/node.dart';
import '../core/node_builder.dart';
import '../accessors/cube_texture_node.dart';
import '../../textures/cube_texture.dart';

/// Node that provides diffuse irradiance from an environment map.
/// 
/// Irradiance nodes sample pre-computed irradiance maps to provide
/// diffuse indirect lighting. The irradiance map is typically generated
/// by convolving an environment map with a cosine-weighted hemisphere.
class IrradianceNode extends Node {
  /// Irradiance cube texture (pre-convolved environment map)
  final CubeTexture? irradianceMap;
  
  /// Normal vector node for sampling direction
  final Node normalNode;
  
  /// Intensity multiplier
  final double intensity;
  
  IrradianceNode({
    this.irradianceMap,
    required this.normalNode,
    this.intensity = 1.0,
  }) {
    nodeType = 'IrradianceNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    // Analyze normal node
    normalNode.build(builder, 'vec3');
    
    // Register irradiance map uniform
    if (irradianceMap != null) {
      builder.addUniform('irradianceMap', 'samplerCube');
      builder.addUniform('irradianceIntensity', 'float');
    }
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    if (irradianceMap == null) {
      // No irradiance map, return black
      return 'vec3(0.0)';
    }
    
    String normal = normalNode.build(builder, 'vec3');
    
    // Sample irradiance map using normal
    String irradianceMapUniform = builder.getUniformFromNode(
      this, 'samplerCube', 'irradianceMap'
    );
    
    String sample = 'texture($irradianceMapUniform, $normal).rgb';
    
    if (intensity != 1.0) {
      String intensityUniform = builder.getUniformFromNode(
        this, 'float', 'irradianceIntensity'
      );
      return '$sample * $intensityUniform';
    }
    
    return sample;
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['normalNode'] = normalNode.toJSON();
    json['intensity'] = intensity;
    return json;
  }
}
