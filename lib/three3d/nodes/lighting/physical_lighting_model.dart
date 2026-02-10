import '../core/node.dart';
import '../functions/code_node.dart';
import 'lighting_model.dart';

/// Physically-based lighting model using Cook-Torrance BRDF.
/// 
/// Implements a full PBR (Physically Based Rendering) lighting model with:
/// - Cook-Torrance specular BRDF
/// - Lambert diffuse BRDF
/// - Fresnel effect (Schlick approximation)
/// - GGX normal distribution function
/// - Smith geometry function
/// - Image-based lighting (IBL) for indirect lighting
/// 
/// This lighting model is suitable for realistic materials and follows
/// energy conservation principles.
class PhysicalLightingModel extends LightingModel {
  /// Albedo color node (base color)
  final Node albedo;
  
  /// Roughness node (0 = smooth, 1 = rough)
  final Node roughness;
  
  /// Metalness node (0 = dielectric, 1 = metal)
  final Node metalness;
  
  /// Fresnel reflectance at normal incidence (F0)
  /// For dielectrics, this is typically 0.04
  /// For metals, this is derived from the albedo
  Node? f0Node;
  
  /// Environment map for indirect lighting
  Node? environmentMap;
  
  /// Irradiance map for diffuse indirect lighting
  Node? irradianceMap;
  
  /// BRDF lookup texture for IBL
  Node? brdfLUT;
  
  /// Ambient occlusion node
  Node? aoNode;
  
  PhysicalLightingModel({
    required this.albedo,
    required this.roughness,
    required this.metalness,
    this.f0Node,
    this.environmentMap,
    this.irradianceMap,
    this.brdfLUT,
    this.aoNode,
  });
  
  @override
  String get name => 'Physical';
  
  @override
  Node direct(LightingContext context) {
    // Compute F0 (base reflectivity)
    // For dielectrics: F0 = 0.04
    // For metals: F0 = albedo
    Node f0 = f0Node ?? _computeF0();
    
    // Compute half vector if not provided
    Node h = context.halfVector ?? 
      MathNode('normalize', context.lightDirection.add(context.viewDirection));
    
    // Compute dot products
    Node nDotL = MathNode('max', 
      MathNode('dot', context.normal, context.lightDirection),
      ConstantNode(0.0)
    );
    
    Node nDotV = MathNode('max',
      MathNode('dot', context.normal, context.viewDirection),
      ConstantNode(0.0)
    );
    
    Node nDotH = MathNode('max',
      MathNode('dot', context.normal, h),
      ConstantNode(0.0)
    );
    
    Node vDotH = MathNode('max',
      MathNode('dot', context.viewDirection, h),
      ConstantNode(0.0)
    );
    
    // Cook-Torrance BRDF components
    Node fresnel = _fresnelSchlick(vDotH, f0);
    Node distribution = _distributionGGX(nDotH, roughness);
    Node geometry = _geometrySmith(nDotV, nDotL, roughness);
    
    // Specular BRDF
    Node numerator = distribution.mul(geometry).mul(fresnel);
    Node denominator = ConstantNode(4.0)
      .mul(nDotV)
      .mul(nDotL)
      .add(ConstantNode(0.0001)); // Prevent division by zero
    
    Node specular = numerator.div(denominator);
    
    // Diffuse component
    // kD = (1 - F) * (1 - metalness)
    // Metals have no diffuse component
    Node kD = ConstantNode(1.0).toVec3()
      .sub(fresnel)
      .mul(ConstantNode(1.0).sub(metalness));
    
    Node diffuse = kD.mul(albedo).div(ConstantNode(3.14159265359)); // Divide by PI
    
    // Combine diffuse and specular
    Node brdf = diffuse.add(specular);
    
    // Final lighting
    Node radiance = context.lightColor;
    Node result = brdf.mul(radiance).mul(nDotL);
    
    // Apply shadow if available
    if (context.shadowFactor != null) {
      result = result.mul(context.shadowFactor!);
    }
    
    return result;
  }
  
  @override
  Node indirect(LightingContext context) {
    // If no environment maps provided, return black
    if (irradianceMap == null && environmentMap == null) {
      return ConstantNode(0.0).toVec3();
    }
    
    // Compute F0
    Node f0 = f0Node ?? _computeF0();
    
    Node nDotV = MathNode('max',
      MathNode('dot', context.normal, context.viewDirection),
      ConstantNode(0.0)
    );
    
    // Fresnel for indirect lighting (roughness-dependent)
    Node fresnel = _fresnelSchlickRoughness(nDotV, f0, roughness);
    
    // Diffuse indirect lighting
    Node kD = ConstantNode(1.0).toVec3()
      .sub(fresnel)
      .mul(ConstantNode(1.0).sub(metalness));
    
    Node diffuseIndirect = ConstantNode(0.0).toVec3();
    if (irradianceMap != null) {
      // Sample irradiance map with normal
      diffuseIndirect = _sampleIrradiance(context.normal)
        .mul(albedo);
    }
    
    // Specular indirect lighting (IBL)
    Node specularIndirect = ConstantNode(0.0).toVec3();
    if (environmentMap != null && brdfLUT != null) {
      // Reflection vector
      Node r = MathNode('reflect',
        context.viewDirection.mul(ConstantNode(-1.0)),
        context.normal
      );
      
      // Sample prefiltered environment map
      Node prefilteredColor = _sampleEnvironment(r, roughness);
      
      // Sample BRDF LUT
      Node brdf = _sampleBRDFLUT(nDotV, roughness);
      
      // Combine
      specularIndirect = prefilteredColor.mul(
        fresnel.mul(_extractX(brdf)).add(_extractY(brdf))
      );
    }
    
    // Combine diffuse and specular indirect
    Node indirect = kD.mul(diffuseIndirect).add(specularIndirect);
    
    // Apply ambient occlusion if available
    Node ao = aoNode ?? ConstantNode(1.0);
    indirect = indirect.mul(ao);
    
    return indirect;
  }
  
  @override
  Node ambientOcclusion(LightingContext context) {
    return aoNode ?? ConstantNode(1.0);
  }
  
  // ============================================================================
  // Helper Methods - BRDF Functions
  // ============================================================================
  
  /// Compute F0 based on metalness and albedo
  Node _computeF0() {
    // F0 for dielectrics is 0.04
    Node dielectricF0 = ConstantNode(0.04).toVec3();
    
    // For metals, F0 is the albedo color
    // Lerp between dielectric and metal F0 based on metalness
    return _mix(dielectricF0, albedo, metalness);
  }
  
  /// Fresnel-Schlick approximation
  Node _fresnelSchlick(Node cosTheta, Node f0) {
    // F = F0 + (1 - F0) * (1 - cosTheta)^5
    Node oneMinusCos = ConstantNode(1.0).sub(cosTheta);
    Node pow5 = MathNode('pow', oneMinusCos, ConstantNode(5.0));
    
    return f0.add(
      ConstantNode(1.0).toVec3().sub(f0).mul(pow5)
    );
  }
  
  /// Fresnel-Schlick with roughness for indirect lighting
  Node _fresnelSchlickRoughness(Node cosTheta, Node f0, Node roughness) {
    // F = F0 + (max(1 - roughness, F0) - F0) * (1 - cosTheta)^5
    Node oneMinusCos = ConstantNode(1.0).sub(cosTheta);
    Node pow5 = MathNode('pow', oneMinusCos, ConstantNode(5.0));
    
    Node maxTerm = MathNode('max',
      ConstantNode(1.0).sub(roughness).toVec3(),
      f0
    );
    
    return f0.add(maxTerm.sub(f0).mul(pow5));
  }
  
  /// GGX/Trowbridge-Reitz normal distribution function
  Node _distributionGGX(Node nDotH, Node roughness) {
    // D = α² / (π * ((NdotH)² * (α² - 1) + 1)²)
    // where α = roughness²
    Node alpha = roughness.mul(roughness);
    Node alphaSq = alpha.mul(alpha);
    
    Node nDotHSq = nDotH.mul(nDotH);
    Node denom = nDotHSq.mul(alphaSq.sub(ConstantNode(1.0))).add(ConstantNode(1.0));
    denom = ConstantNode(3.14159265359).mul(denom).mul(denom);
    
    return alphaSq.div(denom);
  }
  
  /// Smith's geometry function (Schlick-GGX)
  Node _geometrySmith(Node nDotV, Node nDotL, Node roughness) {
    // G = G1(NdotV) * G1(NdotL)
    Node ggx1 = _geometrySchlickGGX(nDotV, roughness);
    Node ggx2 = _geometrySchlickGGX(nDotL, roughness);
    
    return ggx1.mul(ggx2);
  }
  
  /// Schlick-GGX geometry function
  Node _geometrySchlickGGX(Node nDotV, Node roughness) {
    // k = (roughness + 1)² / 8 (for direct lighting)
    Node r = roughness.add(ConstantNode(1.0));
    Node k = r.mul(r).div(ConstantNode(8.0));
    
    Node denom = nDotV.mul(ConstantNode(1.0).sub(k)).add(k);
    
    return nDotV.div(denom);
  }
  
  // ============================================================================
  // Helper Methods - Texture Sampling
  // ============================================================================
  
  /// Sample irradiance map
  Node _sampleIrradiance(Node normal) {
    if (irradianceMap == null) {
      return ConstantNode(0.0).toVec3();
    }
    
    // This would be implemented with actual texture sampling
    // For now, return a placeholder
    return CodeNode(
      'texture(irradianceMap, ${normal.build(null as dynamic, 'vec3')}).rgb',
      includes: {'normal': normal}
    );
  }
  
  /// Sample environment map with roughness-based mip level
  Node _sampleEnvironment(Node reflectionVec, Node roughness) {
    if (environmentMap == null) {
      return ConstantNode(0.0).toVec3();
    }
    
    // Roughness determines mip level
    Node lod = roughness.mul(ConstantNode(4.0)); // Assuming 5 mip levels
    
    return CodeNode(
      'textureLod(environmentMap, ${reflectionVec.build(null as dynamic, 'vec3')}, ${lod.build(null as dynamic, 'float')}).rgb',
      includes: {
        'reflectionVec': reflectionVec,
        'lod': lod,
      }
    );
  }
  
  /// Sample BRDF lookup texture
  Node _sampleBRDFLUT(Node nDotV, Node roughness) {
    if (brdfLUT == null) {
      return Vec2Node(1.0, 0.0);
    }
    
    return CodeNode(
      'texture(brdfLUT, vec2(${nDotV.build(null as dynamic, 'float')}, ${roughness.build(null as dynamic, 'float')})).rg',
      includes: {
        'nDotV': nDotV,
        'roughness': roughness,
      }
    );
  }
  
  // ============================================================================
  // Helper Methods - Utility
  // ============================================================================
  
  /// Mix/lerp between two values
  Node _mix(Node a, Node b, Node t) {
    return MathNode('mix', a, b, t);
  }
  
  /// Extract X component from vec2
  Node _extractX(Node vec) {
    return CodeNode(
      '${vec.build(null as dynamic, 'vec2')}.x',
      includes: {'vec': vec}
    );
  }
  
  /// Extract Y component from vec2
  Node _extractY(Node vec) {
    return CodeNode(
      '${vec.build(null as dynamic, 'vec2')}.y',
      includes: {'vec': vec}
    );
  }
}
