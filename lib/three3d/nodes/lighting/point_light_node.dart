import '../../lights/point_light.dart';
import '../core/node.dart';
import '../core/node_builder.dart';
import '../functions/code_node.dart';
import 'lighting_model.dart';

/// Node that computes point light contribution.
/// 
/// Point lights emit light in all directions from a single point in space,
/// like a light bulb. They have position and can have distance attenuation.
class PointLightNode extends Node {
  /// The point light source
  final PointLight light;
  
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
  
  PointLightNode({
    required this.light,
    required this.lightingModel,
    required this.worldPositionNode,
    required this.normalNode,
    required this.viewDirectionNode,
    required this.materialNode,
  }) {
    nodeType = 'PointLightNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    // Register light uniforms
    builder.addUniform('pointLightPosition', 'vec3');
    builder.addUniform('pointLightColor', 'vec3');
    builder.addUniform('pointLightDistance', 'float');
    builder.addUniform('pointLightDecay', 'float');
    
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
      this, 'vec3', 'pointLightPosition_${light.uuid}'
    );
    String colorUniform = builder.getUniformFromNode(
      this, 'vec3', 'pointLightColor_${light.uuid}'
    );
    String distanceUniform = builder.getUniformFromNode(
      this, 'float', 'pointLightDistance_${light.uuid}'
    );
    String decayUniform = builder.getUniformFromNode(
      this, 'float', 'pointLightDecay_${light.uuid}'
    );
    
    // Compute light direction and distance
    String worldPos = worldPositionNode.build(builder, 'vec3');
    
    // Create code node for light vector calculation
    Node lightVectorNode = CodeNode('''
      vec3 lightVector_${light.uuid} = $positionUniform - $worldPos;
      float lightDistance_${light.uuid} = length(lightVector_${light.uuid});
      vec3 lightDirection_${light.uuid} = normalize(lightVector_${light.uuid});
    ''');
    
    // Build the light vector calculation
    lightVectorNode.build(builder, 'void');
    
    // Compute attenuation
    Node attenuationNode = _computeAttenuation(
      'lightDistance_${light.uuid}',
      distanceUniform,
      decayUniform
    );
    
    String attenuation = attenuationNode.build(builder, 'float');
    
    // Create attenuated light color
    Node attenuatedColorNode = CodeNode(
      '$colorUniform * $attenuation',
      includes: {}
    );
    
    // Build lighting context
    LightingContext context = LightingContext(
      lightDirection: _UniformNode('lightDirection_${light.uuid}'),
      lightColor: attenuatedColorNode,
      viewDirection: viewDirectionNode,
      normal: normalNode,
      material: materialNode,
      lightDistance: _UniformNode('lightDistance_${light.uuid}'),
    );
    
    // Compute lighting using the lighting model
    Node lightingResult = lightingModel.direct(context);
    
    return lightingResult.build(builder, output);
  }
  
  /// Compute distance attenuation for point light
  Node _computeAttenuation(String distanceVar, String maxDistanceUniform, String decayUniform) {
    // Physical attenuation: 1 / (distance^decay)
    // With smooth cutoff at max distance
    return CodeNode('''
      float attenuation_${light.uuid};
      if ($maxDistanceUniform > 0.0) {
        attenuation_${light.uuid} = pow(clamp(1.0 - pow($distanceVar / $maxDistanceUniform, 4.0), 0.0, 1.0), 2.0) / 
          (pow($distanceVar, $decayUniform) + 1.0);
      } else {
        attenuation_${light.uuid} = 1.0 / (pow($distanceVar, $decayUniform) + 1.0);
      }
      attenuation_${light.uuid}
    ''');
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
  
  /// Get the light distance for uniform updates
  double getLightDistance() {
    return light.distance?.toDouble() ?? 0.0;
  }
  
  /// Get the light decay for uniform updates
  double getLightDecay() {
    return light.decay?.toDouble() ?? 1.0;
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

/// Helper node that represents a uniform or variable value
class _UniformNode extends Node {
  final String name;
  
  _UniformNode(this.name) {
    nodeType = '_UniformNode';
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    return name;
  }
}
