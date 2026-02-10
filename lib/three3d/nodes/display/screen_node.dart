import 'package:three_dart_v2/three3d/nodes/core/node.dart';
import 'package:three_dart_v2/three3d/nodes/core/node_builder.dart';

/// Node that provides screen-space coordinates and information.
/// 
/// ScreenNode generates screen-space UV coordinates and other screen-related
/// data. This is essential for effects that need to sample from the viewport
/// or perform screen-space calculations.
/// 
/// Output modes:
/// - 'uv': Screen UV coordinates [0,1] (default)
/// - 'coordinate': Screen pixel coordinates
/// - 'viewport': Viewport size (vec2)
/// - 'size': Screen size in pixels (vec2)
/// 
/// Example:
/// ```dart
/// // Get screen UV coordinates
/// ScreenNode screenUV = ScreenNode();
/// 
/// // Get screen pixel coordinates
/// ScreenNode screenCoord = ScreenNode(mode: 'coordinate');
/// 
/// // Get viewport size
/// ScreenNode viewportSize = ScreenNode(mode: 'viewport');
/// ```
class ScreenNode extends Node {
  /// The output mode ('uv', 'coordinate', 'viewport', 'size')
  final String mode;
  
  /// Create a screen-space node
  /// 
  /// [mode] - The type of screen data to output (default: 'uv')
  ScreenNode({
    this.mode = 'uv',
  }) {
    nodeType = 'ScreenNode';
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    switch (mode.toLowerCase()) {
      case 'uv':
        return _generateScreenUV(builder);
        
      case 'coordinate':
        return _generateScreenCoordinate(builder);
        
      case 'viewport':
        return _generateViewportSize(builder);
        
      case 'size':
        return _generateScreenSize(builder);
        
      default:
        builder.addFlowCode('// Warning: Unknown ScreenNode mode "$mode", using "uv"');
        return _generateScreenUV(builder);
    }
  }
  
  /// Generate screen UV coordinates [0,1]
  String _generateScreenUV(NodeBuilder builder) {
    // gl_FragCoord provides pixel coordinates
    // We need to divide by viewport size to get UV coordinates
    if (!builder.hasUniform('viewportSize')) {
      builder.addUniform('viewportSize', 'vec2');
    }
    
    return '(gl_FragCoord.xy / viewportSize)';
  }
  
  /// Generate screen pixel coordinates
  String _generateScreenCoordinate(NodeBuilder builder) {
    // gl_FragCoord provides pixel coordinates directly
    return 'gl_FragCoord.xy';
  }
  
  /// Generate viewport size
  String _generateViewportSize(NodeBuilder builder) {
    if (!builder.hasUniform('viewportSize')) {
      builder.addUniform('viewportSize', 'vec2');
    }
    
    return 'viewportSize';
  }
  
  /// Generate screen size (same as viewport size in most cases)
  String _generateScreenSize(NodeBuilder builder) {
    if (!builder.hasUniform('viewportSize')) {
      builder.addUniform('viewportSize', 'vec2');
    }
    
    return 'viewportSize';
  }
  
  @override
  Node? getHash(NodeBuilder builder) {
    // Include mode in hash
    return this;
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['mode'] = mode;
    return json;
  }
}
