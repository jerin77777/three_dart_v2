import '../../lights/light.dart';
import '../core/node.dart';
import '../core/node_builder.dart';
import '../functions/code_node.dart';

/// Node that computes shadow factor for a light.
/// 
/// Shadow nodes sample shadow maps to determine if a surface point
/// is in shadow. Returns a value between 0 (fully shadowed) and 1 (fully lit).
class ShadowNode extends Node {
  /// The light casting the shadow
  final Light light;
  
  /// World position node (surface position in world space)
  final Node worldPositionNode;
  
  /// Whether to use PCF (Percentage Closer Filtering) for soft shadows
  final bool usePCF;
  
  /// PCF sample radius (larger = softer shadows)
  final double pcfRadius;
  
  ShadowNode({
    required this.light,
    required this.worldPositionNode,
    this.usePCF = true,
    this.pcfRadius = 1.0,
  }) {
    nodeType = 'ShadowNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    // Register shadow uniforms
    builder.addUniform('shadowMap', 'sampler2D');
    builder.addUniform('shadowMatrix', 'mat4');
    builder.addUniform('shadowBias', 'float');
    builder.addUniform('shadowRadius', 'float');
    builder.addUniform('shadowMapSize', 'vec2');
    
    // Analyze dependencies
    worldPositionNode.build(builder, 'vec3');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    // Get uniform names
    String shadowMapUniform = builder.getUniformFromNode(
      this, 'sampler2D', 'shadowMap_${light.uuid}'
    );
    String shadowMatrixUniform = builder.getUniformFromNode(
      this, 'mat4', 'shadowMatrix_${light.uuid}'
    );
    String shadowBiasUniform = builder.getUniformFromNode(
      this, 'float', 'shadowBias_${light.uuid}'
    );
    String shadowRadiusUniform = builder.getUniformFromNode(
      this, 'float', 'shadowRadius_${light.uuid}'
    );
    String shadowMapSizeUniform = builder.getUniformFromNode(
      this, 'vec2', 'shadowMapSize_${light.uuid}'
    );
    
    String worldPos = worldPositionNode.build(builder, 'vec3');
    
    if (usePCF) {
      // PCF shadow sampling for soft shadows
      return _generatePCFShadow(
        worldPos,
        shadowMapUniform,
        shadowMatrixUniform,
        shadowBiasUniform,
        shadowRadiusUniform,
        shadowMapSizeUniform,
      );
    } else {
      // Hard shadow sampling
      return _generateHardShadow(
        worldPos,
        shadowMapUniform,
        shadowMatrixUniform,
        shadowBiasUniform,
      );
    }
  }
  
  /// Generate hard shadow code (single sample)
  String _generateHardShadow(
    String worldPos,
    String shadowMap,
    String shadowMatrix,
    String shadowBias,
  ) {
    Node shadowNode = CodeNode('''
      // Transform world position to shadow space
      vec4 shadowCoord_${light.uuid} = $shadowMatrix * vec4($worldPos, 1.0);
      shadowCoord_${light.uuid}.xyz /= shadowCoord_${light.uuid}.w;
      shadowCoord_${light.uuid}.xyz = shadowCoord_${light.uuid}.xyz * 0.5 + 0.5;
      
      // Sample shadow map
      float shadowDepth_${light.uuid} = texture($shadowMap, shadowCoord_${light.uuid}.xy).r;
      float currentDepth_${light.uuid} = shadowCoord_${light.uuid}.z - $shadowBias;
      
      // Compare depths
      float shadow_${light.uuid} = currentDepth_${light.uuid} > shadowDepth_${light.uuid} ? 0.0 : 1.0;
      
      // Handle out of bounds
      if (shadowCoord_${light.uuid}.x < 0.0 || shadowCoord_${light.uuid}.x > 1.0 ||
          shadowCoord_${light.uuid}.y < 0.0 || shadowCoord_${light.uuid}.y > 1.0 ||
          shadowCoord_${light.uuid}.z > 1.0) {
        shadow_${light.uuid} = 1.0;
      }
      
      shadow_${light.uuid}
    ''');
    
    return shadowNode.generate(null as dynamic, 'float');
  }
  
  /// Generate PCF shadow code (multiple samples for soft shadows)
  String _generatePCFShadow(
    String worldPos,
    String shadowMap,
    String shadowMatrix,
    String shadowBias,
    String shadowRadius,
    String shadowMapSize,
  ) {
    Node shadowNode = CodeNode('''
      // Transform world position to shadow space
      vec4 shadowCoord_${light.uuid} = $shadowMatrix * vec4($worldPos, 1.0);
      shadowCoord_${light.uuid}.xyz /= shadowCoord_${light.uuid}.w;
      shadowCoord_${light.uuid}.xyz = shadowCoord_${light.uuid}.xyz * 0.5 + 0.5;
      
      float currentDepth_${light.uuid} = shadowCoord_${light.uuid}.z - $shadowBias;
      
      // PCF sampling
      float shadow_${light.uuid} = 0.0;
      vec2 texelSize_${light.uuid} = $shadowRadius / $shadowMapSize;
      
      for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
          vec2 offset_${light.uuid} = vec2(float(x), float(y)) * texelSize_${light.uuid};
          float shadowDepth_${light.uuid} = texture($shadowMap, shadowCoord_${light.uuid}.xy + offset_${light.uuid}).r;
          shadow_${light.uuid} += currentDepth_${light.uuid} > shadowDepth_${light.uuid} ? 0.0 : 1.0;
        }
      }
      shadow_${light.uuid} /= 9.0;
      
      // Handle out of bounds
      if (shadowCoord_${light.uuid}.x < 0.0 || shadowCoord_${light.uuid}.x > 1.0 ||
          shadowCoord_${light.uuid}.y < 0.0 || shadowCoord_${light.uuid}.y > 1.0 ||
          shadowCoord_${light.uuid}.z > 1.0) {
        shadow_${light.uuid} = 1.0;
      }
      
      shadow_${light.uuid}
    ''');
    
    return shadowNode.generate(null as dynamic, 'float');
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['lightUuid'] = light.uuid;
    json['worldPositionNode'] = worldPositionNode.toJSON();
    json['usePCF'] = usePCF;
    json['pcfRadius'] = pcfRadius;
    return json;
  }
}
