import '../core/node.dart';

/// Context data for lighting calculations.
/// 
/// Contains all the information needed to compute lighting contributions,
/// including light properties, surface properties, and view direction.
class LightingContext {
  /// Direction from surface to light (normalized)
  final Node lightDirection;
  
  /// Color and intensity of the light
  final Node lightColor;
  
  /// Direction from surface to viewer (normalized)
  final Node viewDirection;
  
  /// Surface normal (normalized)
  final Node normal;
  
  /// Material properties node
  final Node material;
  
  /// Half vector between light and view directions (for specular)
  Node? halfVector;
  
  /// Distance from light to surface (for attenuation)
  Node? lightDistance;
  
  /// Spot light cone attenuation
  Node? spotAttenuation;
  
  /// Shadow factor (0 = fully shadowed, 1 = fully lit)
  Node? shadowFactor;
  
  LightingContext({
    required this.lightDirection,
    required this.lightColor,
    required this.viewDirection,
    required this.normal,
    required this.material,
    this.halfVector,
    this.lightDistance,
    this.spotAttenuation,
    this.shadowFactor,
  });
}

/// Base class for lighting models.
/// 
/// A lighting model defines how light interacts with a surface by implementing
/// direct and indirect lighting calculations. Different lighting models can
/// implement different shading equations (Lambert, Phong, PBR, etc.).
abstract class LightingModel {
  /// Name of this lighting model
  String get name;
  
  /// Compute direct lighting contribution.
  /// 
  /// Direct lighting comes from light sources in the scene (directional,
  /// point, spot, area lights). This method should return a node that
  /// computes the lighting contribution for a single light.
  /// 
  /// The returned node should output a vec3 representing the RGB color
  /// contribution from this light.
  Node direct(LightingContext context);
  
  /// Compute indirect lighting contribution.
  /// 
  /// Indirect lighting comes from environment maps, irradiance probes,
  /// and ambient occlusion. This method should return a node that
  /// computes the indirect lighting contribution.
  /// 
  /// The returned node should output a vec3 representing the RGB color
  /// contribution from indirect lighting.
  Node indirect(LightingContext context);
  
  /// Optional: Compute ambient occlusion factor.
  /// 
  /// Returns a node that outputs a float in [0, 1] where 0 is fully
  /// occluded and 1 is fully lit. Default implementation returns 1.0.
  Node ambientOcclusion(LightingContext context) {
    return ConstantNode(1.0);
  }
  
  /// Optional: Modify the final lighting result.
  /// 
  /// This can be used to apply tone mapping, color grading, or other
  /// post-processing effects. Default implementation returns the input.
  Node finish(Node lightingResult) {
    return lightingResult;
  }
}

/// Basic Lambert diffuse lighting model.
/// 
/// Implements simple diffuse lighting using Lambert's cosine law.
/// This is the simplest lighting model and is suitable for matte surfaces.
class LambertLightingModel extends LightingModel {
  @override
  String get name => 'Lambert';
  
  @override
  Node direct(LightingContext context) {
    // Lambert diffuse: color * max(dot(N, L), 0)
    Node nDotL = MathNode('max', 
      MathNode('dot', context.normal, context.lightDirection),
      ConstantNode(0.0)
    );
    
    Node diffuse = context.lightColor.mul(nDotL);
    
    // Apply shadow if available
    if (context.shadowFactor != null) {
      diffuse = diffuse.mul(context.shadowFactor!);
    }
    
    return diffuse;
  }
  
  @override
  Node indirect(LightingContext context) {
    // Simple ambient lighting
    return ConstantNode(0.0).toVec3();
  }
}

/// Phong lighting model with specular highlights.
/// 
/// Implements Phong shading with diffuse and specular components.
class PhongLightingModel extends LightingModel {
  /// Specular shininess exponent
  final double shininess;
  
  /// Specular color/intensity
  final Node specularColor;
  
  PhongLightingModel({
    this.shininess = 30.0,
    Node? specularColor,
  }) : specularColor = specularColor ?? ConstantNode(1.0).toVec3();
  
  @override
  String get name => 'Phong';
  
  @override
  Node direct(LightingContext context) {
    // Diffuse component
    Node nDotL = MathNode('max', 
      MathNode('dot', context.normal, context.lightDirection),
      ConstantNode(0.0)
    );
    
    Node diffuse = context.lightColor.mul(nDotL);
    
    // Specular component (Phong reflection model)
    // R = reflect(-L, N)
    Node reflectDir = MathNode('reflect',
      context.lightDirection.mul(ConstantNode(-1.0)),
      context.normal
    );
    
    Node rDotV = MathNode('max',
      MathNode('dot', reflectDir, context.viewDirection),
      ConstantNode(0.0)
    );
    
    Node specular = MathNode('pow', rDotV, ConstantNode(shininess))
      .mul(specularColor)
      .mul(context.lightColor);
    
    Node result = diffuse.add(specular);
    
    // Apply shadow if available
    if (context.shadowFactor != null) {
      result = result.mul(context.shadowFactor!);
    }
    
    return result;
  }
  
  @override
  Node indirect(LightingContext context) {
    // Simple ambient lighting
    return ConstantNode(0.0).toVec3();
  }
}

/// Basic lighting model (no lighting calculations).
/// 
/// Simply returns the material color without any lighting.
/// Useful for unlit materials or debugging.
class BasicLightingModel extends LightingModel {
  @override
  String get name => 'Basic';
  
  @override
  Node direct(LightingContext context) {
    return ConstantNode(0.0).toVec3();
  }
  
  @override
  Node indirect(LightingContext context) {
    return ConstantNode(0.0).toVec3();
  }
}
