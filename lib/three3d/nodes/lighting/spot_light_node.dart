import '../../lights/spot_light.dart';
import '../core/node.dart';
import '../core/node_builder.dart';
import '../functions/code_node.dart';
import 'lighting_model.dart';
import 'dart:math' as math;

/// Node that computes spot light contribution.
/// 
/// Spot lights emit light in a cone from a single point, like a flashlight.
/// They have position, direction, cone angle, and penumbra for soft edges.
class SpotLightNode extends Node {
  /// The spot light source
  final SpotLight light;
  
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
  
  SpotLightNode({
    required this.light,
    required this.lightingModel,
    required this.worldPositionNode,
    required this.normalNode,
    required this.viewDirectionNode,
    required this.materialNode,
  }) {
    nodeType = 'SpotLightNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    // Register light uniforms
    builder.addUniform('spotLightPosition', 'vec3');
    builder.addUniform('spotLightDirection', 'vec3');
    builder.addUniform('spotLightColor', 'vec3');
    builder.addUniform('spotLightDistance', 'float');
    builder.addUniform('spotLightDecay', 'float');
    builder.addUniform('spotLightConeCos', 'float');
    builder.addUniform('spotLightPenumbraCos', 'float');
    
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
      this, 'vec3', 'spotLightPosition_${light.uuid}'
    );
    String directionUniform = builder.getUniformFromNode(
      this, 'vec3', 'spotLightDirection_${light.uuid}'
    );
    String colorUniform = builder.getUniformFromNode(
      this, 'vec3', 'spotLightColor_${light.uuid}'
    );
    String distanceUniform = builder.getUniformFromNode(
      this, 'float', 'spotLightDistance_${light.uuid}'
    );
    String decayUniform = builder.getUniformFromNode(
      this, 'float', 'spotLightDecay_${light.uuid}'
    );
    String coneCosUniform = builder.getUniformFromNode(
      this, 'float', 'spotLightConeCos_${light.uuid}'
    );
    String penumbraCosUniform = builder.getUniformFromNode(
      this, 'float', 'spotLightPenumbraCos_${light.uuid}'
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
    
    // Compute distance attenuation
    Node distanceAttenuationNode = _computeDistanceAttenuation(
      'lightDistance_${light.uuid}',
      distanceUniform,
      decayUniform
    );
    
    String distanceAttenuation = distanceAttenuationNode.build(builder, 'float');
    
    // Compute spot cone attenuation
    Node spotAttenuationNode = _computeSpotAttenuation(
      'lightDirection_${light.uuid}',
      directionUniform,
      coneCosUniform,
      penumbraCosUniform
    );
    
    String spotAttenuation = spotAttenuationNode.build(builder, 'float');
    
    // Combine attenuations
    Node totalAttenuationNode = CodeNode(
      '$distanceAttenuation * $spotAttenuation',
      includes: {}
    );
    
    String totalAttenuation = totalAttenuationNode.build(builder, 'float');
    
    // Create attenuated light color
    Node attenuatedColorNode = CodeNode(
      '$colorUniform * $totalAttenuation',
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
      spotAttenuation: _UniformNode(spotAttenuation),
    );
    
    // Compute lighting using the lighting model
    Node lightingResult = lightingModel.direct(context);
    
    return lightingResult.build(builder, output);
  }
  
  /// Compute distance attenuation for spot light
  Node _computeDistanceAttenuation(String distanceVar, String maxDistanceUniform, String decayUniform) {
    return CodeNode('''
      float distAttenuation_${light.uuid};
      if ($maxDistanceUniform > 0.0) {
        distAttenuation_${light.uuid} = pow(clamp(1.0 - pow($distanceVar / $maxDistanceUniform, 4.0), 0.0, 1.0), 2.0) / 
          (pow($distanceVar, $decayUniform) + 1.0);
      } else {
        distAttenuation_${light.uuid} = 1.0 / (pow($distanceVar, $decayUniform) + 1.0);
      }
      distAttenuation_${light.uuid}
    ''');
  }
  
  /// Compute spot cone attenuation with smooth penumbra
  Node _computeSpotAttenuation(String lightDirVar, String spotDirUniform, String coneCosUniform, String penumbraCosUniform) {
    return CodeNode('''
      float angleCos_${light.uuid} = dot($lightDirVar, -$spotDirUniform);
      float spotAttenuation_${light.uuid} = smoothstep($coneCosUniform, $penumbraCosUniform, angleCos_${light.uuid});
      spotAttenuation_${light.uuid}
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
  
  /// Get the light direction for uniform updates
  List<double> getLightDirection() {
    // Direction from light to target
    double dx = light.target!.position.x - light.position.x;
    double dy = light.target!.position.y - light.position.y;
    double dz = light.target!.position.z - light.position.z;
    
    // Normalize
    double length = math.sqrt(dx * dx + dy * dy + dz * dz);
    if (length > 0) {
      dx /= length;
      dy /= length;
      dz /= length;
    }
    
    return [dx, dy, dz];
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
  
  /// Get the cone cosine for uniform updates
  double getConeCos() {
    return math.cos(light.angle?.toDouble() ?? 0.0);
  }
  
  /// Get the penumbra cosine for uniform updates
  double getPenumbraCos() {
    double angle = light.angle?.toDouble() ?? 0.0;
    double penumbra = light.penumbra?.toDouble() ?? 0.0;
    return math.cos(angle * (1.0 - penumbra));
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
