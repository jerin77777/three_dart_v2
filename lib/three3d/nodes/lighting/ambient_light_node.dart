import '../../lights/ambient_light.dart';
import '../core/node.dart';
import '../core/node_builder.dart';

/// Node that provides ambient light contribution.
/// 
/// Ambient light illuminates all objects equally from all directions.
/// It has no position or direction and provides a base level of illumination.
class AmbientLightNode extends Node {
  /// The ambient light source
  final AmbientLight light;
  
  AmbientLightNode(this.light) {
    nodeType = 'AmbientLightNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    // Register light uniform
    builder.addUniform('ambientLightColor', 'vec3');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    // Get uniform name for this light's color
    String colorUniform = builder.getUniformFromNode(this, 'vec3');
    
    // Ambient light simply returns its color * intensity
    // The color uniform will be updated with light.color * light.intensity
    return colorUniform;
  }
  
  /// Get the light color value for uniform updates
  List<double> getLightColor() {
    double r = light.color!.r * light.intensity;
    double g = light.color!.g * light.intensity;
    double b = light.color!.b * light.intensity;
    return [r, g, b];
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['lightUuid'] = light.uuid;
    return json;
  }
}
