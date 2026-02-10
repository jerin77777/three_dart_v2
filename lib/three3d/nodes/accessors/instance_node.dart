import 'package:three_dart_v2/three3d/nodes/core/node.dart';
import 'package:three_dart_v2/three3d/nodes/core/node_builder.dart';

/// Node that accesses instance-specific data for instanced rendering.
/// 
/// InstanceNode provides access to per-instance attributes such as
/// instance transforms, colors, or custom data in instanced rendering.
/// 
/// Example:
/// ```dart
/// InstanceNode instanceColorNode = InstanceNode('color');
/// InstanceNode instanceMatrixNode = InstanceNode('matrix');
/// ```
class InstanceNode extends Node {
  /// Name of the instance attribute to access
  final String attributeName;
  
  /// Create an instance data accessor node
  /// 
  /// [attributeName] - Name of the instance attribute (e.g., 'color', 'matrix')
  InstanceNode(this.attributeName) {
    nodeType = 'InstanceNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    super.analyze(builder);
    
    // Register instance attribute
    String type = _getAttributeType(attributeName);
    builder.getAttributeFromNode(this, type);
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    // Instance attributes are prefixed with 'instance_'
    return 'instance_$attributeName';
  }
  
  /// Determine the GLSL type for an instance attribute
  String _getAttributeType(String attribute) {
    switch (attribute) {
      case 'color':
        return 'vec3';
      
      case 'matrix':
        return 'mat4';
      
      case 'offset':
      case 'scale':
        return 'vec3';
      
      case 'rotation':
        return 'vec4'; // Quaternion
      
      default:
        return 'vec3'; // Default type
    }
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['attributeName'] = attributeName;
    return json;
  }
}

/// Node that accesses InstancedMesh-specific data.
/// 
/// InstancedMeshNode provides specialized access to instanced mesh
/// properties including instance matrices and instance colors.
/// 
/// Example:
/// ```dart
/// InstancedMeshNode matrixNode = InstancedMeshNode('instanceMatrix');
/// InstancedMeshNode colorNode = InstancedMeshNode('instanceColor');
/// ```
class InstancedMeshNode extends Node {
  /// Type of instanced mesh data to access
  final String dataType;
  
  /// Create an instanced mesh data accessor node
  /// 
  /// [dataType] - Type of data ('instanceMatrix', 'instanceColor', etc.)
  InstancedMeshNode(this.dataType) {
    nodeType = 'InstancedMeshNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    super.analyze(builder);
    
    // Register instance attribute
    String type = _getDataType(dataType);
    builder.getAttributeFromNode(this, type);
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    // Generate code based on data type
    switch (dataType) {
      case 'instanceMatrix':
        // Instance matrix is typically stored as 4 vec4 attributes
        return 'mat4(instanceMatrix0, instanceMatrix1, instanceMatrix2, instanceMatrix3)';
      
      case 'instanceColor':
        return 'instanceColor';
      
      default:
        return 'instance_$dataType';
    }
  }
  
  /// Determine the GLSL type for instanced mesh data
  String _getDataType(String data) {
    switch (data) {
      case 'instanceMatrix':
        return 'mat4';
      
      case 'instanceColor':
        return 'vec3';
      
      default:
        return 'vec3';
    }
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['dataType'] = dataType;
    return json;
  }
}

