import 'package:three_dart_v2/three3d/nodes/core/node.dart';
import 'package:three_dart_v2/three3d/nodes/core/node_builder.dart';

/// Node that applies normal mapping to perturb surface normals.
/// 
/// NormalMapNode takes a normal map texture and applies it to modify
/// the surface normal, creating the illusion of detailed geometry without
/// additional polygons. This is essential for realistic surface detail.
/// 
/// The normal map is expected to be in tangent space, with RGB values
/// representing XYZ normal directions.
/// 
/// Example:
/// ```dart
/// Node normalMapTexture = TextureNode(normalTexture, uvNode);
/// Node scale = Vec2Node(1.0, 1.0);
/// NormalMapNode normalNode = NormalMapNode(
///   normalMapTexture,
///   scaleNode: scale
/// );
/// ```
class NormalMapNode extends Node {
  /// The normal map texture node (should output vec3 or vec4)
  final Node normalMapNode;
  
  /// Optional scale factor for normal intensity (should output vec2)
  final Node? scaleNode;
  
  /// Optional UV coordinates node (should output vec2)
  final Node? uvNode;
  
  /// Whether the normal map is in object space (false = tangent space)
  final bool isObjectSpace;
  
  /// Create a normal mapping node
  /// 
  /// [normalMapNode] - Node providing the normal map texture
  /// [scaleNode] - Optional node for normal intensity scaling (defaults to vec2(1.0, 1.0))
  /// [uvNode] - Optional UV coordinates (uses default UVs if not provided)
  /// [isObjectSpace] - Whether the normal map is in object space (default: false = tangent space)
  NormalMapNode(
    this.normalMapNode, {
    this.scaleNode,
    this.uvNode,
    this.isObjectSpace = false,
  }) {
    nodeType = 'NormalMapNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    super.analyze(builder);
    
    // Build dependencies
    normalMapNode.build(builder, 'vec3');
    scaleNode?.build(builder, 'vec2');
    uvNode?.build(builder, 'vec2');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    // Get the normal map value
    String normalMap = normalMapNode.build(builder, 'vec3');
    
    // Get scale (default to vec2(1.0, 1.0))
    String scale = scaleNode?.build(builder, 'vec2') ?? 'vec2(1.0, 1.0)';
    
    if (isObjectSpace) {
      return _generateObjectSpaceNormalMap(builder, normalMap, scale);
    } else {
      return _generateTangentSpaceNormalMap(builder, normalMap, scale);
    }
  }
  
  /// Generate tangent space normal mapping code
  String _generateTangentSpaceNormalMap(NodeBuilder builder, String normalMap, String scale) {
    if (!builder.hasFunction('perturbNormal2Arb')) {
      builder.addFunction('''
vec3 perturbNormal2Arb(vec3 normalMapValue, vec2 scale) {
  // Decode normal map from [0,1] to [-1,1]
  vec3 tangentNormal = normalMapValue * 2.0 - 1.0;
  
  // Apply scale to XY components
  tangentNormal.xy *= scale;
  
  // Normalize the result
  tangentNormal = normalize(tangentNormal);
  
  // Get derivatives for TBN matrix construction
  vec3 pos_dx = dFdx(vPosition);
  vec3 pos_dy = dFdy(vPosition);
  vec2 tex_dx = dFdx(vUv);
  vec2 tex_dy = dFdy(vUv);
  
  // Construct tangent and bitangent
  vec3 T = normalize(pos_dx * tex_dy.t - pos_dy * tex_dx.t);
  vec3 B = normalize(-pos_dx * tex_dy.s + pos_dy * tex_dx.s);
  
  // Get the normal
  vec3 N = normalize(vNormal);
  
  // Construct TBN matrix
  mat3 TBN = mat3(T, B, N);
  
  // Transform tangent space normal to world space
  return normalize(TBN * tangentNormal);
}
''');
    }
    
    return 'perturbNormal2Arb($normalMap, $scale)';
  }
  
  /// Generate object space normal mapping code
  String _generateObjectSpaceNormalMap(NodeBuilder builder, String normalMap, String scale) {
    if (!builder.hasFunction('objectSpaceNormalMap')) {
      builder.addFunction('''
vec3 objectSpaceNormalMap(vec3 normalMapValue, vec2 scale) {
  // Decode normal map from [0,1] to [-1,1]
  vec3 objectNormal = normalMapValue * 2.0 - 1.0;
  
  // Apply scale to XY components
  objectNormal.xy *= scale;
  
  // Transform from object space to world space
  vec3 worldNormal = normalize(normalMatrix * objectNormal);
  
  return worldNormal;
}
''');
    }
    
    return 'objectSpaceNormalMap($normalMap, $scale)';
  }
  
  @override
  Node? getHash(NodeBuilder builder) {
    // Include normal map properties in hash
    return this;
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['normalMapNode'] = normalMapNode.toJSON();
    if (scaleNode != null) {
      json['scaleNode'] = scaleNode!.toJSON();
    }
    if (uvNode != null) {
      json['uvNode'] = uvNode!.toJSON();
    }
    json['isObjectSpace'] = isObjectSpace;
    return json;
  }
}
