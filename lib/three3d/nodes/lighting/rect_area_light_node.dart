import '../../lights/rect_area_light.dart';
import '../core/node.dart';
import '../core/node_builder.dart';
import '../functions/code_node.dart';
import 'lighting_model.dart';

/// Node that computes rectangular area light contribution.
/// 
/// Rectangular area lights emit light from a rectangular surface,
/// providing more realistic lighting for architectural scenes.
/// They require more complex calculations than point/spot lights.
class RectAreaLightNode extends Node {
  /// The rectangular area light source
  final RectAreaLight light;
  
  /// The lighting model to use for calculations
  final LightingModel lightingModel;
  
  /// World position node (surface position in world space)
  final Node worldPositionNode;
  
  /// Normal vector node
  final Node normalNode;
  
  /// View direction node
  final Node viewDirectionNode;
  
  /// Material properties node
  final Node materialNode;
  
  RectAreaLightNode({
    required this.light,
    required this.lightingModel,
    required this.worldPositionNode,
    required this.normalNode,
    required this.viewDirectionNode,
    required this.materialNode,
  }) {
    nodeType = 'RectAreaLightNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    // Register light uniforms
    builder.addUniform('rectAreaLightPosition', 'vec3');
    builder.addUniform('rectAreaLightColor', 'vec3');
    builder.addUniform('rectAreaLightHalfWidth', 'vec3');
    builder.addUniform('rectAreaLightHalfHeight', 'vec3');
    
    // Analyze dependencies
    worldPositionNode.build(builder, 'vec3');
    normalNode.build(builder, 'vec3');
    viewDirectionNode.build(builder, 'vec3');
    materialNode.build(builder, 'auto');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    // Get uniform names
    String positionUniform = builder.getUniformFromNode(
      this, 'vec3', 'rectAreaLightPosition_${light.uuid}'
    );
    String colorUniform = builder.getUniformFromNode(
      this, 'vec3', 'rectAreaLightColor_${light.uuid}'
    );
    String halfWidthUniform = builder.getUniformFromNode(
      this, 'vec3', 'rectAreaLightHalfWidth_${light.uuid}'
    );
    String halfHeightUniform = builder.getUniformFromNode(
      this, 'vec3', 'rectAreaLightHalfHeight_${light.uuid}'
    );
    
    String worldPos = worldPositionNode.build(builder, 'vec3');
    String normal = normalNode.build(builder, 'vec3');
    
    // Compute rect area light contribution using LTC (Linearly Transformed Cosines)
    // This is a simplified version - full implementation would use LTC lookup tables
    Node rectLightNode = CodeNode('''
      // Compute rect area light contribution
      vec3 rectLightDir_${light.uuid} = $positionUniform - $worldPos;
      float rectLightDist_${light.uuid} = length(rectLightDir_${light.uuid});
      vec3 rectLightL_${light.uuid} = normalize(rectLightDir_${light.uuid});
      
      // Compute the four corners of the rectangle
      vec3 corner1_${light.uuid} = $positionUniform - $halfWidthUniform - $halfHeightUniform;
      vec3 corner2_${light.uuid} = $positionUniform + $halfWidthUniform - $halfHeightUniform;
      vec3 corner3_${light.uuid} = $positionUniform + $halfWidthUniform + $halfHeightUniform;
      vec3 corner4_${light.uuid} = $positionUniform - $halfWidthUniform + $halfHeightUniform;
      
      // Vectors from surface point to corners
      vec3 v1_${light.uuid} = normalize(corner1_${light.uuid} - $worldPos);
      vec3 v2_${light.uuid} = normalize(corner2_${light.uuid} - $worldPos);
      vec3 v3_${light.uuid} = normalize(corner3_${light.uuid} - $worldPos);
      vec3 v4_${light.uuid} = normalize(corner4_${light.uuid} - $worldPos);
      
      // Compute solid angle (simplified approximation)
      float solidAngle_${light.uuid} = 0.0;
      solidAngle_${light.uuid} += acos(dot(v1_${light.uuid}, v2_${light.uuid}));
      solidAngle_${light.uuid} += acos(dot(v2_${light.uuid}, v3_${light.uuid}));
      solidAngle_${light.uuid} += acos(dot(v3_${light.uuid}, v4_${light.uuid}));
      solidAngle_${light.uuid} += acos(dot(v4_${light.uuid}, v1_${light.uuid}));
      solidAngle_${light.uuid} -= 2.0 * 3.14159265359;
      
      // Compute irradiance
      float irradiance_${light.uuid} = max(0.0, solidAngle_${light.uuid} * max(0.0, dot($normal, rectLightL_${light.uuid})));
      
      // Final color
      vec3 rectLightColor_${light.uuid} = $colorUniform * irradiance_${light.uuid};
      rectLightColor_${light.uuid}
    ''');
    
    return rectLightNode.build(builder, output);
  }
  
  /// Get the light position for uniform updates
  List<double> getLightPosition() {
    return [
      light.position.x.toDouble(),
      light.position.y.toDouble(),
      light.position.z.toDouble(),
    ];
  }
  
  /// Get the light color value for uniform updates
  List<double> getLightColor() {
    double r = light.color!.r * light.intensity;
    double g = light.color!.g * light.intensity;
    double b = light.color!.b * light.intensity;
    return [r, g, b];
  }
  
  /// Get the half-width vector for uniform updates
  List<double> getHalfWidth() {
    // This would need to be computed from the light's transform
    // For now, return a placeholder based on width
    double halfWidth = (light.width?.toDouble() ?? 1.0) / 2.0;
    return [halfWidth, 0.0, 0.0];
  }
  
  /// Get the half-height vector for uniform updates
  List<double> getHalfHeight() {
    // This would need to be computed from the light's transform
    // For now, return a placeholder based on height
    double halfHeight = (light.height?.toDouble() ?? 1.0) / 2.0;
    return [0.0, halfHeight, 0.0];
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['lightUuid'] = light.uuid;
    json['worldPositionNode'] = worldPositionNode.toJSON();
    json['normalNode'] = normalNode.toJSON();
    json['viewDirectionNode'] = viewDirectionNode.toJSON();
    json['materialNode'] = materialNode.toJSON();
    return json;
  }
}
