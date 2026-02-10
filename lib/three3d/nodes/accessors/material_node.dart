import 'package:three_dart_v2/three3d/materials/index.dart';
import 'package:three_dart_v2/three3d/nodes/core/node.dart';
import 'package:three_dart_v2/three3d/nodes/core/node_builder.dart';

/// Node that accesses material properties.
/// 
/// MaterialNode provides access to properties of the current material
/// being rendered, such as color, opacity, roughness, metalness, etc.
/// 
/// Example:
/// ```dart
/// MaterialNode colorNode = MaterialNode('color');
/// MaterialNode opacityNode = MaterialNode('opacity');
/// ```
class MaterialNode extends Node {
  /// Name of the material property to access
  final String propertyName;
  
  /// Create a material property accessor node
  /// 
  /// [propertyName] - Name of the property (e.g., 'color', 'opacity', 'roughness')
  MaterialNode(this.propertyName) {
    nodeType = 'MaterialNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    super.analyze(builder);
    
    // Verify material context exists
    if (builder.material == null) {
      throw Exception('MaterialNode requires material context');
    }
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    Material? material = builder.material;
    
    if (material == null) {
      throw Exception('MaterialNode requires material context');
    }
    
    // Get the property value type
    String type = _getPropertyType(propertyName);
    
    // Create a uniform for this material property
    String uniformName = builder.getUniformFromNode(this, type);
    
    return uniformName;
  }
  
  /// Determine the GLSL type for a material property
  String _getPropertyType(String property) {
    switch (property) {
      case 'color':
      case 'emissive':
      case 'specular':
        return 'vec3';
      
      case 'opacity':
      case 'roughness':
      case 'metalness':
      case 'clearcoat':
      case 'clearcoatRoughness':
      case 'ior':
      case 'reflectivity':
      case 'iridescence':
      case 'iridescenceIOR':
      case 'sheen':
      case 'sheenRoughness':
      case 'transmission':
      case 'thickness':
      case 'attenuationDistance':
      case 'shininess':
        return 'float';
      
      case 'normalScale':
      case 'clearcoatNormalScale':
        return 'vec2';
      
      case 'attenuationColor':
      case 'sheenColor':
        return 'vec3';
      
      default:
        // Default to float for unknown properties
        return 'float';
    }
  }
  
  @override
  Node? getHash(NodeBuilder builder) {
    // Include property name in hash
    return this;
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['propertyName'] = propertyName;
    return json;
  }
}

/// Node that references another material's properties.
/// 
/// MaterialReferenceNode allows accessing properties from a different
/// material than the one currently being rendered.
/// 
/// Example:
/// ```dart
/// Material referenceMaterial = MeshStandardMaterial();
/// MaterialReferenceNode refNode = MaterialReferenceNode(referenceMaterial, 'color');
/// ```
class MaterialReferenceNode extends Node {
  /// The material to reference
  final Material material;
  
  /// Name of the property to access
  final String propertyName;
  
  /// Create a material reference node
  /// 
  /// [material] - The material to reference
  /// [propertyName] - Name of the property to access
  MaterialReferenceNode(this.material, this.propertyName) {
    nodeType = 'MaterialReferenceNode';
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    // Get the property value type
    String type = _getPropertyType(propertyName);
    
    // Create a uniform for this referenced material property
    String uniformName = builder.getUniformFromNode(this, type);
    
    return uniformName;
  }
  
  /// Determine the GLSL type for a material property
  String _getPropertyType(String property) {
    switch (property) {
      case 'color':
      case 'emissive':
      case 'specular':
        return 'vec3';
      
      case 'opacity':
      case 'roughness':
      case 'metalness':
      case 'clearcoat':
      case 'clearcoatRoughness':
      case 'ior':
      case 'reflectivity':
      case 'iridescence':
      case 'iridescenceIOR':
      case 'sheen':
      case 'sheenRoughness':
      case 'transmission':
      case 'thickness':
      case 'attenuationDistance':
      case 'shininess':
        return 'float';
      
      case 'normalScale':
      case 'clearcoatNormalScale':
        return 'vec2';
      
      case 'attenuationColor':
      case 'sheenColor':
        return 'vec3';
      
      default:
        return 'float';
    }
  }
  
  @override
  Node? getHash(NodeBuilder builder) {
    // Include material and property in hash
    return this;
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['materialUuid'] = material.uuid;
    json['propertyName'] = propertyName;
    return json;
  }
}

