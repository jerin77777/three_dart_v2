import 'package:three_dart_v2/three3d/nodes/core/node.dart';
import 'package:three_dart_v2/three3d/nodes/core/node_builder.dart';

/// Node that accesses storage buffer data for compute shaders.
/// 
/// StorageBufferNode provides read/write access to GPU storage buffers,
/// which are used for general-purpose GPU computing (GPGPU) operations.
/// 
/// Example:
/// ```dart
/// StorageBufferNode particleBuffer = StorageBufferNode('particles', 'vec4');
/// Node indexNode = ConstantNode(0);
/// StorageBufferElementNode particle = StorageBufferElementNode(particleBuffer, indexNode);
/// ```
class StorageBufferNode extends Node {
  /// Name of the storage buffer
  final String bufferName;
  
  /// Type of data stored in the buffer
  final String dataType;
  
  /// Whether this buffer is read-only
  final bool readOnly;
  
  /// Create a storage buffer accessor node
  /// 
  /// [bufferName] - Name of the storage buffer
  /// [dataType] - GLSL type of the buffer elements (e.g., 'vec4', 'float')
  /// [readOnly] - Whether the buffer is read-only (default: false)
  StorageBufferNode(this.bufferName, this.dataType, {this.readOnly = false}) {
    nodeType = 'StorageBufferNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    super.analyze(builder);
    
    // Verify compute shader context
    if (builder.shaderStage != 'compute') {
      throw Exception('StorageBufferNode can only be used in compute shaders');
    }
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    // Storage buffers are declared at the shader level
    // This node just returns the buffer name for access
    return bufferName;
  }
  
  /// Get the buffer declaration for the shader
  String getDeclaration() {
    String qualifier = readOnly ? 'readonly' : '';
    return 'layout(std430) $qualifier buffer ${bufferName}Buffer { $dataType $bufferName[]; };';
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['bufferName'] = bufferName;
    json['dataType'] = dataType;
    json['readOnly'] = readOnly;
    return json;
  }
}

/// Node that accesses a specific element in a storage buffer.
/// 
/// StorageBufferElementNode provides indexed access to storage buffer elements.
/// 
/// Example:
/// ```dart
/// StorageBufferNode buffer = StorageBufferNode('data', 'vec4');
/// Node index = ConstantNode(5);
/// StorageBufferElementNode element = StorageBufferElementNode(buffer, index);
/// ```
class StorageBufferElementNode extends Node {
  /// The storage buffer to access
  final StorageBufferNode bufferNode;
  
  /// Node providing the index
  final Node indexNode;
  
  /// Create a storage buffer element accessor node
  /// 
  /// [bufferNode] - The storage buffer to access
  /// [indexNode] - Node that provides the index (should output int or uint)
  StorageBufferElementNode(this.bufferNode, this.indexNode) {
    nodeType = 'StorageBufferElementNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    super.analyze(builder);
    
    // Build dependencies
    bufferNode.build(builder, 'auto');
    indexNode.build(builder, 'int');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    String bufferName = bufferNode.generate(builder, 'auto');
    String index = indexNode.build(builder, 'int');
    
    return '$bufferName[$index]';
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['bufferNode'] = bufferNode.toJSON();
    json['indexNode'] = indexNode.toJSON();
    return json;
  }
}

/// Node that accesses storage textures for compute shaders.
/// 
/// StorageTextureNode provides read/write access to GPU storage textures,
/// which allow compute shaders to write directly to texture data.
/// 
/// Example:
/// ```dart
/// StorageTextureNode outputTexture = StorageTextureNode('outputTex', 'rgba8');
/// Node coordNode = Vec2Node(0, 0);
/// ```
class StorageTextureNode extends Node {
  /// Name of the storage texture
  final String textureName;
  
  /// Format of the storage texture (e.g., 'rgba8', 'r32f')
  final String format;
  
  /// Whether this texture is read-only
  final bool readOnly;
  
  /// Create a storage texture accessor node
  /// 
  /// [textureName] - Name of the storage texture
  /// [format] - Image format (e.g., 'rgba8', 'r32f', 'rgba16f')
  /// [readOnly] - Whether the texture is read-only (default: false)
  StorageTextureNode(this.textureName, this.format, {this.readOnly = false}) {
    nodeType = 'StorageTextureNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    super.analyze(builder);
    
    // Verify compute shader context
    if (builder.shaderStage != 'compute') {
      throw Exception('StorageTextureNode can only be used in compute shaders');
    }
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    // Storage textures are declared at the shader level
    return textureName;
  }
  
  /// Get the texture declaration for the shader
  String getDeclaration() {
    String qualifier = readOnly ? 'readonly' : 'writeonly';
    return 'layout($format) uniform $qualifier image2D $textureName;';
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['textureName'] = textureName;
    json['format'] = format;
    json['readOnly'] = readOnly;
    return json;
  }
}

/// Node that reads from a storage texture.
/// 
/// StorageTextureReadNode performs an imageLoad operation on a storage texture.
/// 
/// Example:
/// ```dart
/// StorageTextureNode texture = StorageTextureNode('inputTex', 'rgba8', readOnly: true);
/// Node coordNode = Vec2Node(10, 20);
/// StorageTextureReadNode readNode = StorageTextureReadNode(texture, coordNode);
/// ```
class StorageTextureReadNode extends Node {
  /// The storage texture to read from
  final StorageTextureNode textureNode;
  
  /// Node providing the texture coordinates
  final Node coordNode;
  
  /// Create a storage texture read node
  /// 
  /// [textureNode] - The storage texture to read from
  /// [coordNode] - Node that provides the coordinates (should output ivec2)
  StorageTextureReadNode(this.textureNode, this.coordNode) {
    nodeType = 'StorageTextureReadNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    super.analyze(builder);
    
    // Build dependencies
    textureNode.build(builder, 'auto');
    coordNode.build(builder, 'ivec2');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    String textureName = textureNode.generate(builder, 'auto');
    String coord = coordNode.build(builder, 'ivec2');
    
    return 'imageLoad($textureName, $coord)';
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['textureNode'] = textureNode.toJSON();
    json['coordNode'] = coordNode.toJSON();
    return json;
  }
}

/// Node that writes to a storage texture.
/// 
/// StorageTextureWriteNode performs an imageStore operation on a storage texture.
/// 
/// Example:
/// ```dart
/// StorageTextureNode texture = StorageTextureNode('outputTex', 'rgba8');
/// Node coordNode = Vec2Node(10, 20);
/// Node valueNode = Vec4Node(1.0, 0.0, 0.0, 1.0);
/// StorageTextureWriteNode writeNode = StorageTextureWriteNode(texture, coordNode, valueNode);
/// ```
class StorageTextureWriteNode extends Node {
  /// The storage texture to write to
  final StorageTextureNode textureNode;
  
  /// Node providing the texture coordinates
  final Node coordNode;
  
  /// Node providing the value to write
  final Node valueNode;
  
  /// Create a storage texture write node
  /// 
  /// [textureNode] - The storage texture to write to
  /// [coordNode] - Node that provides the coordinates (should output ivec2)
  /// [valueNode] - Node that provides the value to write (should output vec4)
  StorageTextureWriteNode(this.textureNode, this.coordNode, this.valueNode) {
    nodeType = 'StorageTextureWriteNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    super.analyze(builder);
    
    // Build dependencies
    textureNode.build(builder, 'auto');
    coordNode.build(builder, 'ivec2');
    valueNode.build(builder, 'vec4');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    String textureName = textureNode.generate(builder, 'auto');
    String coord = coordNode.build(builder, 'ivec2');
    String value = valueNode.build(builder, 'vec4');
    
    // imageStore is a statement, not an expression
    builder.addFlowCode('imageStore($textureName, $coord, $value);');
    
    // Return empty string since this is a statement
    return '';
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['textureNode'] = textureNode.toJSON();
    json['coordNode'] = coordNode.toJSON();
    json['valueNode'] = valueNode.toJSON();
    return json;
  }
}

