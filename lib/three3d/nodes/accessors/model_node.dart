import 'package:three_dart_v2/three3d/core/index.dart';
import 'package:three_dart_v2/three3d/nodes/core/node.dart';
import 'package:three_dart_v2/three3d/nodes/core/node_builder.dart';

/// Node that accesses model transformation data.
/// 
/// ModelNode provides access to the model matrix and related
/// transformation properties of the object being rendered.
/// 
/// Example:
/// ```dart
/// ModelNode modelMatrixNode = ModelNode('modelMatrix');
/// ModelNode modelViewMatrixNode = ModelNode('modelViewMatrix');
/// ```
class ModelNode extends Node {
  /// Type of model data to access
  final String dataType;
  
  /// Create a model data accessor node
  /// 
  /// [dataType] - Type of data ('modelMatrix', 'modelViewMatrix', 'normalMatrix', etc.)
  ModelNode(this.dataType) {
    nodeType = 'ModelNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    super.analyze(builder);
    
    // Verify object context exists
    if (builder.object == null) {
      throw Exception('ModelNode requires object context');
    }
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    if (builder.object == null) {
      throw Exception('ModelNode requires object context');
    }
    
    // Get the data type
    String type = _getDataType(dataType);
    
    // Create a uniform for this model property
    String uniformName = builder.getUniformFromNode(this, type);
    
    return uniformName;
  }
  
  /// Determine the GLSL type for model data
  String _getDataType(String data) {
    switch (data) {
      case 'modelMatrix':
      case 'modelViewMatrix':
      case 'projectionMatrix':
      case 'viewMatrix':
        return 'mat4';
      
      case 'normalMatrix':
        return 'mat3';
      
      case 'position':
      case 'scale':
        return 'vec3';
      
      case 'rotation':
        return 'vec4'; // Quaternion
      
      default:
        return 'mat4';
    }
  }
  
  @override
  Node? getHash(NodeBuilder builder) {
    // Include data type in hash
    return this;
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['dataType'] = dataType;
    return json;
  }
}

/// Node that accesses Object3D properties.
/// 
/// Object3DNode provides access to properties of the 3D object
/// being rendered, such as position, rotation, scale, and custom properties.
/// 
/// Example:
/// ```dart
/// Object3DNode positionNode = Object3DNode('position');
/// Object3DNode scaleNode = Object3DNode('scale');
/// ```
class Object3DNode extends Node {
  /// The Object3D to reference (null means current object)
  final Object3D? object;
  
  /// Name of the property to access
  final String propertyName;
  
  /// Create an Object3D property accessor node
  /// 
  /// [propertyName] - Name of the property to access
  /// [object] - Optional specific object to reference (null = current object)
  Object3DNode(this.propertyName, {this.object}) {
    nodeType = 'Object3DNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    super.analyze(builder);
    
    // Verify object context exists if no specific object provided
    if (object == null && builder.object == null) {
      throw Exception('Object3DNode requires object context');
    }
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    // Use provided object or builder's current object
    Object3D? targetObject = object ?? builder.object;
    
    if (targetObject == null) {
      throw Exception('Object3DNode requires object context');
    }
    
    // Get the property type
    String type = _getPropertyType(propertyName);
    
    // Create a uniform for this object property
    String uniformName = builder.getUniformFromNode(this, type);
    
    return uniformName;
  }
  
  /// Determine the GLSL type for an Object3D property
  String _getPropertyType(String property) {
    switch (property) {
      case 'position':
      case 'scale':
      case 'worldPosition':
        return 'vec3';
      
      case 'rotation':
      case 'quaternion':
        return 'vec4'; // Quaternion
      
      case 'matrix':
      case 'matrixWorld':
        return 'mat4';
      
      case 'visible':
        return 'bool';
      
      case 'id':
        return 'int';
      
      default:
        return 'float'; // Default for custom properties
    }
  }
  
  @override
  Node? getHash(NodeBuilder builder) {
    // Include property name and object in hash
    return this;
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['propertyName'] = propertyName;
    if (object != null) {
      json['objectUuid'] = object!.uuid;
    }
    return json;
  }
}

