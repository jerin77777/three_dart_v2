import '../../lights/directional_light.dart';
import '../core/node.dart';
import '../core/node_builder.dart';
import 'lighting_model.dart';
import 'dart:math' as math;

/// Node that computes directional light contribution.
/// 
/// Directional lights emit parallel rays in a single direction,
/// like sunlight. They have no position, only a direction.
class DirectionalLightNode extends Node {
  /// The directional light source
  final DirectionalLight light;
  
  /// The lighting model to use for calculations
  final LightingModel lightingModel;
  
  /// Normal vector node
  final Node normalNode;
  
  /// View direction node
  final Node viewDirectionNode;
  
  /// Material properties node
  final Node materialNode;
  
  DirectionalLightNode({
    required this.light,
    required this.lightingModel,
    required this.normalNode,
    required this.viewDirectionNode,
    required this.materialNode,
  }) {
    nodeType = 'DirectionalLightNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    // Register light uniforms
    builder.addUniform('directionalLightDirection', 'vec3');
    builder.addUniform('directionalLightColor', 'vec3');
    
    // Analyze dependencies
    normalNode.build(builder, 'vec3');
    viewDirectionNode.build(builder, 'vec3');
    materialNode.build(builder, 'auto');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    // Create unique uniform names for this light
    String directionUniform = 'u_directionalLightDirection_${light.uuid}';
    String colorUniform = 'u_directionalLightColor_${light.uuid}';
    
    // Register uniforms manually
    builder.addUniform(directionUniform, 'vec3');
    builder.addUniform(colorUniform, 'vec3');
    
    // Build lighting context
    LightingContext context = LightingContext(
      lightDirection: _DirectionUniformNode(directionUniform),
      lightColor: _ColorUniformNode(colorUniform),
      viewDirection: viewDirectionNode,
      normal: normalNode,
      material: materialNode,
    );
    
    // Compute lighting using the lighting model
    Node lightingResult = lightingModel.direct(context);
    
    return lightingResult.build(builder, output);
  }
  
  /// Get the light direction for uniform updates
  /// Direction is from surface to light (opposite of light's forward direction)
  List<double> getLightDirection() {
    // In three.js, directional light direction is from light to target
    // For lighting calculations, we need direction from surface to light
    double x = -light.position.x;
    double y = -light.position.y;
    double z = -light.position.z;
    
    // Normalize
    double length = math.sqrt(x * x + y * y + z * z);
    if (length > 0) {
      x /= length;
      y /= length;
      z /= length;
    }
    
    return [x, y, z];
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
    json['normalNode'] = normalNode.toJSON();
    json['viewDirectionNode'] = viewDirectionNode.toJSON();
    json['materialNode'] = materialNode.toJSON();
    return json;
  }
}

/// Helper node that represents a uniform value
class _DirectionUniformNode extends Node {
  final String uniformName;
  
  _DirectionUniformNode(this.uniformName) {
    nodeType = '_DirectionUniformNode';
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    return uniformName;
  }
}

class _ColorUniformNode extends Node {
  final String uniformName;
  
  _ColorUniformNode(this.uniformName) {
    nodeType = '_ColorUniformNode';
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    return uniformName;
  }
}
