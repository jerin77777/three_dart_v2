import '../core/node.dart';
import '../core/node_builder.dart';
import '../functions/code_node.dart';

/// Node that provides access to lighting context data.
/// 
/// LightingContextNode provides commonly needed values for lighting
/// calculations, such as world position, normal, view direction, etc.
/// These are computed once and can be reused by multiple light nodes.
class LightingContextNode extends Node {
  /// Type of context data to access
  final LightingContextType contextType;
  
  LightingContextNode(this.contextType) {
    nodeType = 'LightingContextNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    // Register required varyings and uniforms based on context type
    switch (contextType) {
      case LightingContextType.worldPosition:
        builder.addVarying('vWorldPosition', 'vec3');
        break;
      case LightingContextType.worldNormal:
        builder.addVarying('vWorldNormal', 'vec3');
        break;
      case LightingContextType.viewDirection:
        builder.addVarying('vViewPosition', 'vec3');
        builder.addUniform('cameraPosition', 'vec3');
        break;
      case LightingContextType.normal:
        builder.addVarying('vNormal', 'vec3');
        break;
      case LightingContextType.tangent:
        builder.addVarying('vTangent', 'vec3');
        break;
      case LightingContextType.bitangent:
        builder.addVarying('vBitangent', 'vec3');
        break;
      case LightingContextType.uv:
        builder.addVarying('vUv', 'vec2');
        break;
      case LightingContextType.color:
        builder.addVarying('vColor', 'vec3');
        break;
    }
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    switch (contextType) {
      case LightingContextType.worldPosition:
        return 'vWorldPosition';
        
      case LightingContextType.worldNormal:
        return 'normalize(vWorldNormal)';
        
      case LightingContextType.viewDirection:
        // View direction is from surface to camera
        String cameraPos = builder.getUniformFromNode(this, 'vec3', 'cameraPosition');
        return 'normalize($cameraPos - vViewPosition)';
        
      case LightingContextType.normal:
        return 'normalize(vNormal)';
        
      case LightingContextType.tangent:
        return 'normalize(vTangent)';
        
      case LightingContextType.bitangent:
        return 'normalize(vBitangent)';
        
      case LightingContextType.uv:
        return 'vUv';
        
      case LightingContextType.color:
        return 'vColor';
    }
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['contextType'] = contextType.toString();
    return json;
  }
}

/// Types of lighting context data that can be accessed
enum LightingContextType {
  /// World-space position of the surface point
  worldPosition,
  
  /// World-space normal vector (interpolated and normalized)
  worldNormal,
  
  /// View direction (from surface to camera)
  viewDirection,
  
  /// View-space or object-space normal
  normal,
  
  /// Tangent vector (for normal mapping)
  tangent,
  
  /// Bitangent vector (for normal mapping)
  bitangent,
  
  /// UV coordinates
  uv,
  
  /// Vertex color
  color,
}

/// Helper nodes for common lighting context access patterns
class WorldPositionNode extends LightingContextNode {
  WorldPositionNode() : super(LightingContextType.worldPosition);
}

class WorldNormalNode extends LightingContextNode {
  WorldNormalNode() : super(LightingContextType.worldNormal);
}

class ViewDirectionNode extends LightingContextNode {
  ViewDirectionNode() : super(LightingContextType.viewDirection);
}

class NormalNode extends LightingContextNode {
  NormalNode() : super(LightingContextType.normal);
}

class TangentNode extends LightingContextNode {
  TangentNode() : super(LightingContextType.tangent);
}

class BitangentNode extends LightingContextNode {
  BitangentNode() : super(LightingContextType.bitangent);
}

class UVNode extends LightingContextNode {
  UVNode() : super(LightingContextType.uv);
}

class VertexColorNode extends LightingContextNode {
  VertexColorNode() : super(LightingContextType.color);
}
