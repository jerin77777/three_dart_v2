import 'package:three_dart_v2/three3d/nodes/core/node.dart';
import 'package:three_dart_v2/three3d/nodes/core/node_builder.dart';

/// Node that applies bump mapping to perturb surface normals.
/// 
/// BumpMapNode takes a height map (grayscale texture) and uses it to
/// perturb the surface normal, creating the illusion of surface detail.
/// Unlike normal mapping which stores explicit normal directions, bump
/// mapping derives normals from height differences.
/// 
/// The bump map is expected to be a grayscale texture where brightness
/// represents height.
/// 
/// Example:
/// ```dart
/// Node bumpTexture = TextureNode(heightTexture, uvNode);
/// Node scale = FloatNode(0.5);
/// BumpMapNode bumpNode = BumpMapNode(
///   bumpTexture,
///   scaleNode: scale
/// );
/// ```
class BumpMapNode extends Node {
  /// The bump/height map texture node (should output float or vec3)
  final Node bumpMapNode;
  
  /// Optional scale factor for bump intensity (should output float)
  final Node? scaleNode;
  
  /// Optional UV coordinates node (should output vec2)
  final Node? uvNode;
  
  /// Create a bump mapping node
  /// 
  /// [bumpMapNode] - Node providing the bump/height map texture
  /// [scaleNode] - Optional node for bump intensity scaling (defaults to 1.0)
  /// [uvNode] - Optional UV coordinates (uses default UVs if not provided)
  BumpMapNode(
    this.bumpMapNode, {
    this.scaleNode,
    this.uvNode,
  }) {
    nodeType = 'BumpMapNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    super.analyze(builder);
    
    // Build dependencies
    bumpMapNode.build(builder, 'float');
    scaleNode?.build(builder, 'float');
    uvNode?.build(builder, 'vec2');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    // Get the bump map value
    String bumpMap = bumpMapNode.build(builder, 'float');
    
    // Get scale (default to 1.0)
    String scale = scaleNode?.build(builder, 'float') ?? '1.0';
    
    return _generateBumpMapping(builder, bumpMap, scale);
  }
  
  /// Generate bump mapping code
  String _generateBumpMapping(NodeBuilder builder, String bumpMap, String scale) {
    if (!builder.hasFunction('perturbNormalArb')) {
      builder.addFunction('''
vec3 perturbNormalArb(float height, float scale) {
  // Calculate height derivatives using screen-space derivatives
  vec2 dSTdx = dFdx(vUv);
  vec2 dSTdy = dFdy(vUv);
  
  // Get position derivatives
  vec3 vSigmaX = dFdx(vPosition);
  vec3 vSigmaY = dFdy(vPosition);
  
  // Get normal
  vec3 vN = normalize(vNormal);
  
  // Calculate tangent vectors
  vec3 vR1 = cross(vSigmaY, vN);
  vec3 vR2 = cross(vN, vSigmaX);
  
  float fDet = dot(vSigmaX, vR1);
  
  // Prevent division by zero
  fDet = sign(fDet) * max(abs(fDet), 1e-10);
  
  // Calculate height gradient
  float dBs = dFdx(height);
  float dBt = dFdy(height);
  
  // Apply scale
  vec3 vSurfGrad = scale * (dBs * vR1 + dBt * vR2) / fDet;
  
  // Perturb normal
  return normalize(vN - vSurfGrad);
}
''');
    }
    
    return 'perturbNormalArb($bumpMap, $scale)';
  }
  
  @override
  Node? getHash(NodeBuilder builder) {
    // Include bump map properties in hash
    return this;
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['bumpMapNode'] = bumpMapNode.toJSON();
    if (scaleNode != null) {
      json['scaleNode'] = scaleNode!.toJSON();
    }
    if (uvNode != null) {
      json['uvNode'] = uvNode!.toJSON();
    }
    return json;
  }
}
