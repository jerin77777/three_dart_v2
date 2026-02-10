import 'package:three_dart_v2/three3d/cameras/index.dart';
import 'package:three_dart_v2/three3d/core/index.dart';
import 'package:three_dart_v2/three3d/materials/index.dart';
import 'package:three_dart_v2/three3d/renderers/index.dart';
import 'package:three_dart_v2/three3d/textures/index.dart';
import 'node.dart';
import 'node_cache.dart';
import 'node_frame.dart';
import 'node_uniform.dart';
import 'node_attribute.dart';
import 'node_varying.dart';

/// Compiles node graphs into executable shader code.
/// 
/// The NodeBuilder follows a three-phase compilation process:
/// 1. Setup: Traverse the node graph and collect dependencies
/// 2. Analyze: Determine caching needs and optimize the graph
/// 3. Generate: Produce final GLSL shader code
class NodeBuilder {
  /// Material being compiled
  Material? material;
  
  /// Geometry being rendered
  BufferGeometry? geometry;
  
  /// Renderer context
  WebGLRenderer? renderer;
  
  /// Object being rendered
  Object3D? object;
  
  /// Camera for the current render
  Camera? camera;
  
  /// Current shader stage ('vertex', 'fragment', 'compute')
  String shaderStage = 'fragment';
  
  /// Map of all nodes in the graph
  final Map<String, Node> nodes = {};
  
  /// Cache for generated node code
  final Map<String, String> nodeCache = {};
  
  /// Uniforms used in the shader
  final Map<String, NodeUniform> uniforms = {};
  
  /// Attributes used in the shader
  final Map<String, NodeAttribute> attributes = {};
  
  /// Varyings passed between shader stages
  final Map<String, NodeVarying> varyings = {};
  
  /// Generated shader code lines
  final List<String> _shaderLines = [];
  
  /// Function declarations
  final List<String> _functions = [];
  
  /// Variable declarations
  final List<String> _variables = [];
  
  /// Flow code (main shader logic)
  final List<String> _flowCode = [];
  
  /// Node cache for reuse
  final NodeCache cache = NodeCache();
  
  /// Current node frame
  NodeFrame? frame;
  
  /// Counter for generating unique variable names
  int _varCounter = 0;
  
  /// Stack for nested operations
  final List<Map<String, dynamic>> _stack = [];
  
  // ============================================================================
  // Build Pipeline
  // ============================================================================
  
  /// Phase 1: Setup - Traverse node graph and collect dependencies
  void setup(Node? outputNode) {
    if (outputNode == null) {
      throw Exception('NodeBuilder.setup: outputNode is required');
    }
    
    // Reset state
    nodes.clear();
    nodeCache.clear();
    _shaderLines.clear();
    _functions.clear();
    _variables.clear();
    _flowCode.clear();
    _varCounter = 0;
    
    // Build the node graph
    outputNode.build(this, 'vec4');
  }
  
  /// Phase 2: Analyze - Determine caching needs and optimize
  void analyze() {
    // Analyze which nodes should be cached (used multiple times)
    Map<String, int> nodeUsage = {};
    
    for (var node in nodes.values) {
      String key = node.uuid;
      nodeUsage[key] = (nodeUsage[key] ?? 0) + 1;
    }
    
    // Mark nodes used multiple times for caching
    for (var entry in nodeUsage.entries) {
      if (entry.value > 1) {
        Node? node = nodes[entry.key];
        if (node != null) {
          // Node should be cached
          String varName = getPropertyName(node);
          nodeCache[node.uuid] = varName;
        }
      }
    }
  }
  
  /// Phase 3: Generate - Produce final shader code
  String generate() {
    StringBuffer shader = StringBuffer();
    
    // Add version directive
    shader.writeln(getVersionDirective());
    shader.writeln();
    
    // Add precision qualifiers
    shader.writeln(getPrecisionQualifiers());
    shader.writeln();
    
    // Add uniform declarations
    for (var uniform in uniforms.values) {
      shader.writeln('uniform ${uniform.type} ${uniform.name};');
    }
    if (uniforms.isNotEmpty) shader.writeln();
    
    // Add attribute declarations (vertex shader only)
    if (shaderStage == 'vertex') {
      for (var attribute in attributes.values) {
        shader.writeln('in ${attribute.type} ${attribute.name};');
      }
      if (attributes.isNotEmpty) shader.writeln();
    }
    
    // Add varying declarations
    for (var varying in varyings.values) {
      if (shaderStage == 'vertex') {
        shader.writeln('out ${varying.type} ${varying.name};');
      } else {
        shader.writeln('in ${varying.type} ${varying.name};');
      }
    }
    if (varyings.isNotEmpty) shader.writeln();
    
    // Add output declarations (fragment shader only)
    if (shaderStage == 'fragment') {
      for (var output in _outputs) {
        shader.writeln(output);
      }
      if (_outputs.isNotEmpty) shader.writeln();
    }
    
    // Add variable declarations
    for (var variable in _variables) {
      shader.writeln(variable);
    }
    if (_variables.isNotEmpty) shader.writeln();
    
    // Add function declarations
    for (var function in _functions) {
      shader.writeln(function);
    }
    if (_functions.isNotEmpty) shader.writeln();
    
    // Add main function
    shader.writeln('void main() {');
    for (var line in _flowCode) {
      shader.writeln('  $line');
    }
    shader.writeln('}');
    
    return shader.toString();
  }
  
  /// Build a complete shader program from a node
  String build(Node? outputNode) {
    setup(outputNode);
    analyze();
    return generate();
  }
  
  // ============================================================================
  // Code Generation Helpers
  // ============================================================================
  
  /// Get a uniform variable for a node
  String getUniformFromNode(Node node, String type) {
    String name = 'u_${getPropertyName(node)}';
    
    if (!uniforms.containsKey(name)) {
      uniforms[name] = NodeUniform(
        name: name,
        type: type,
        node: node,
      );
    }
    
    return name;
  }
  
  /// Get an attribute variable for a node
  String getAttributeFromNode(Node node, String type) {
    String name = 'a_${getPropertyName(node)}';
    
    if (!attributes.containsKey(name)) {
      attributes[name] = NodeAttribute(
        name: name,
        type: type,
      );
    }
    
    return name;
  }
  
  /// Get a varying variable for a node
  String getVaryingFromNode(Node node, String type) {
    String name = 'v_${getPropertyName(node)}';
    
    if (!varyings.containsKey(name)) {
      varyings[name] = NodeVarying(
        name: name,
        type: type,
        node: node,
      );
    }
    
    return name;
  }
  
  /// Get a unique property name for a node
  String getPropertyName(Node node) {
    String? nodeType = node.nodeType;
    if (nodeType != null) {
      return '${nodeType}_${node.uuid.substring(0, 8)}';
    }
    return 'node_${node.uuid.substring(0, 8)}';
  }
  
  /// Generate a unique variable name
  String getUniqueVarName([String prefix = 'v']) {
    return '${prefix}_${_varCounter++}';
  }
  
  // ============================================================================
  // Type System
  // ============================================================================
  
  /// Get the GLSL type of a node
  String getType(Node node) {
    // Default implementation - will be enhanced as nodes are added
    if (node is ConstantNode) return 'float';
    if (node is Vec2Node) return 'vec2';
    if (node is Vec3Node) return 'vec3';
    if (node is Vec4Node) return 'vec4';
    
    // Default to vec4 for unknown types
    return 'vec4';
  }
  
  /// Get vector type for a given length
  String getVectorType(int length) {
    switch (length) {
      case 2: return 'vec2';
      case 3: return 'vec3';
      case 4: return 'vec4';
      default: return 'float';
    }
  }
  
  /// Check if a texture needs color space conversion to linear
  bool needsColorSpaceToLinear(Texture? texture) {
    // TODO: Implement based on texture encoding
    return false;
  }
  
  // ============================================================================
  // Caching and Optimization
  // ============================================================================
  
  /// Check if a node is cached
  bool isNodeCached(Node node) {
    return nodeCache.containsKey(node.uuid);
  }
  
  /// Cache a node's generated code
  void cacheNode(Node node, String code) {
    nodeCache[node.uuid] = code;
  }
  
  /// Get cached code for a node
  String getCachedNode(Node node) {
    return nodeCache[node.uuid] ?? '';
  }
  
  // ============================================================================
  // Code Building Helpers
  // ============================================================================
  
  /// Add a line of flow code (main shader logic)
  void addFlowCode(String code) {
    _flowCode.add(code);
  }
  
  /// Add a function declaration
  void addFunction(String code) {
    _functions.add(code);
  }
  
  /// Check if a function has been declared
  bool hasFunction(String functionName) {
    return _functions.any((f) => f.contains('$functionName('));
  }
  
  /// Add a variable declaration
  void addVariable(String code) {
    _variables.add(code);
  }
  
  /// Add a shader line
  void addLine(String code) {
    _shaderLines.add(code);
  }
  
  /// Check if a uniform has been declared
  bool hasUniform(String uniformName) {
    return uniforms.containsKey(uniformName);
  }
  
  /// Add a uniform declaration
  void addUniform(String name, String type) {
    if (!uniforms.containsKey(name)) {
      uniforms[name] = NodeUniform(
        name: name,
        type: type,
        node: null,
      );
    }
  }
  
  /// Output declarations for fragment shader
  final List<String> _outputs = [];
  
  /// Check if an output has been declared
  bool hasOutput(String outputName) {
    return _outputs.any((o) => o.contains(' $outputName;'));
  }
  
  /// Add an output declaration
  void addOutput(String declaration) {
    if (!_outputs.contains(declaration)) {
      _outputs.add(declaration);
    }
  }
  
  // ============================================================================
  // Platform-Specific Code Generation
  // ============================================================================
  
  /// Get the GLSL version directive for the target platform
  String getVersionDirective() {
    // Default to GLSL ES 3.0 for now
    return '#version 300 es';
  }
  
  /// Get precision qualifiers
  String getPrecisionQualifiers() {
    return 'precision highp float;\nprecision highp int;';
  }
  
  // ============================================================================
  // Stack Management
  // ============================================================================
  
  /// Push a context onto the stack
  void pushStack(Map<String, dynamic> context) {
    _stack.add(context);
  }
  
  /// Pop a context from the stack
  Map<String, dynamic>? popStack() {
    if (_stack.isEmpty) return null;
    return _stack.removeLast();
  }
  
  /// Get the current stack context
  Map<String, dynamic>? getStack() {
    if (_stack.isEmpty) return null;
    return _stack.last;
  }
}
