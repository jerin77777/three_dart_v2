import 'package:three_dart_v2/three3d/core/index.dart';
import 'package:three_dart_v2/three3d/nodes/core/node.dart';
import 'package:three_dart_v2/three3d/nodes/core/node_builder.dart';

/// Node that accesses vertex buffer attributes.
/// 
/// BufferAttributeNode provides access to per-vertex data stored in buffer
/// attributes such as positions, normals, UVs, colors, etc.
/// 
/// Example:
/// ```dart
/// BufferAttribute positionAttr = geometry.getAttribute('position');
/// BufferAttributeNode positionNode = BufferAttributeNode(positionAttr, 'position');
/// ```
class BufferAttributeNode extends Node {
  /// The buffer attribute to access
  final BufferAttribute? bufferAttribute;
  
  /// Name of the attribute in the shader
  final String attributeName;
  
  /// Create a buffer attribute node
  /// 
  /// [bufferAttribute] - The buffer attribute containing the data
  /// [attributeName] - Name to use for the attribute in the shader (e.g., 'position', 'normal', 'uv')
  BufferAttributeNode(this.bufferAttribute, this.attributeName) {
    nodeType = 'BufferAttributeNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    super.analyze(builder);
    
    // Register this attribute with the builder
    if (bufferAttribute != null) {
      String type = _getAttributeType();
      builder.getAttributeFromNode(this, type);
    }
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    // In vertex shader, return the attribute name directly
    // In fragment shader, this would typically be accessed via a varying
    if (builder.shaderStage == 'vertex') {
      return 'a_$attributeName';
    } else {
      // In fragment shader, use varying
      return 'v_$attributeName';
    }
  }
  
  /// Determine the GLSL type based on the buffer attribute
  String _getAttributeType() {
    if (bufferAttribute == null) {
      return 'vec3'; // Default type
    }
    
    int itemSize = bufferAttribute!.itemSize;
    
    switch (itemSize) {
      case 1:
        return 'float';
      case 2:
        return 'vec2';
      case 3:
        return 'vec3';
      case 4:
        return 'vec4';
      default:
        return 'vec3';
    }
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['attributeName'] = attributeName;
    if (bufferAttribute != null) {
      json['itemSize'] = bufferAttribute!.itemSize;
    }
    return json;
  }
}

