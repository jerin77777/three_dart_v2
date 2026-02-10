import '../core/node.dart';
import '../core/node_builder.dart';

/// Node that performs bitcast (type reinterpretation) operations.
/// 
/// Reinterprets the bit pattern of a value as a different type without conversion.
/// For example, reinterpreting a float as an int or vice versa.
/// 
/// Example:
/// ```dart
/// // Reinterpret float bits as int
/// var intBits = BitcastNode(floatNode, 'int');
/// 
/// // Reinterpret int bits as float
/// var floatBits = BitcastNode(intNode, 'float');
/// ```
class BitcastNode extends Node {
  /// The node to reinterpret
  final Node node;
  
  /// The target type to reinterpret as
  final String targetType;
  
  /// Supported bitcast operations
  static const Map<String, String> glslFunctions = {
    'float': 'intBitsToFloat',
    'int': 'floatBitsToInt',
    'uint': 'floatBitsToUint',
  };
  
  BitcastNode(this.node, this.targetType) {
    nodeType = 'BitcastNode';
    
    if (!glslFunctions.containsKey(targetType)) {
      throw ArgumentError(
        'Unsupported bitcast target type: $targetType. '
        'Supported types: ${glslFunctions.keys.join(', ')}'
      );
    }
  }
  
  @override
  void analyze(NodeBuilder builder) {
    node.build(builder, 'auto');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    String value = node.build(builder, 'auto');
    String function = glslFunctions[targetType]!;
    
    return '$function($value)';
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['node'] = node.toJSON();
    json['targetType'] = targetType;
    return json;
  }
  
  /// Create a BitcastNode from JSON
  static BitcastNode? fromJSON(Map<String, dynamic> json) {
    Node? node = Node.fromJSON(json['node']);
    String? targetType = json['targetType'];
    
    if (node == null || targetType == null) return null;
    
    return BitcastNode(node, targetType);
  }
}

/// Node that counts the number of set bits in an integer.
/// 
/// Uses GLSL's bitCount function to count the number of 1 bits.
/// 
/// Example:
/// ```dart
/// // Count bits in an integer
/// var count = BitcountNode(intNode);
/// ```
class BitcountNode extends Node {
  /// The integer node to count bits in
  final Node node;
  
  BitcountNode(this.node) {
    nodeType = 'BitcountNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    node.build(builder, 'auto');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    String value = node.build(builder, 'auto');
    return 'bitCount($value)';
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['node'] = node.toJSON();
    return json;
  }
  
  /// Create a BitcountNode from JSON
  static BitcountNode? fromJSON(Map<String, dynamic> json) {
    Node? node = Node.fromJSON(json['node']);
    if (node == null) return null;
    
    return BitcountNode(node);
  }
}

/// Node that packs float values into a vector.
/// 
/// Packs multiple float values into a single vector type for efficient storage.
/// 
/// Example:
/// ```dart
/// // Pack two floats into a vec2
/// var packed = PackFloatNode([float1, float2]);
/// 
/// // Pack four floats into a vec4
/// var packed4 = PackFloatNode([f1, f2, f3, f4]);
/// ```
class PackFloatNode extends Node {
  /// The float nodes to pack
  final List<Node> nodes;
  
  PackFloatNode(this.nodes) {
    nodeType = 'PackFloatNode';
    
    if (nodes.isEmpty || nodes.length > 4) {
      throw ArgumentError(
        'PackFloatNode requires 1-4 nodes, got ${nodes.length}'
      );
    }
  }
  
  @override
  void analyze(NodeBuilder builder) {
    for (var node in nodes) {
      node.build(builder, 'float');
    }
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    List<String> values = nodes.map((n) => n.build(builder, 'float')).toList();
    
    String vecType = _getVectorType(values.length);
    return '$vecType(${values.join(', ')})';
  }
  
  String _getVectorType(int length) {
    switch (length) {
      case 1:
        return 'float';
      case 2:
        return 'vec2';
      case 3:
        return 'vec3';
      case 4:
        return 'vec4';
      default:
        throw ArgumentError('Invalid vector length: $length');
    }
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['nodes'] = nodes.map((n) => n.toJSON()).toList();
    return json;
  }
  
  /// Create a PackFloatNode from JSON
  static PackFloatNode? fromJSON(Map<String, dynamic> json) {
    List<dynamic>? nodesJson = json['nodes'];
    if (nodesJson == null) return null;
    
    List<Node> nodes = [];
    for (var nodeJson in nodesJson) {
      Node? node = Node.fromJSON(nodeJson);
      if (node == null) return null;
      nodes.add(node);
    }
    
    return PackFloatNode(nodes);
  }
}

/// Node that unpacks a vector into individual float values.
/// 
/// Extracts individual components from a vector.
/// 
/// Example:
/// ```dart
/// // Unpack x component from vec3
/// var x = UnpackFloatNode(vec3Node, 'x');
/// 
/// // Unpack rgb components
/// var r = UnpackFloatNode(colorNode, 'r');
/// var g = UnpackFloatNode(colorNode, 'g');
/// var b = UnpackFloatNode(colorNode, 'b');
/// ```
class UnpackFloatNode extends Node {
  /// The vector node to unpack
  final Node node;
  
  /// The component to extract (x, y, z, w or r, g, b, a)
  final String component;
  
  /// Valid component names
  static const Set<String> validComponents = {
    'x', 'y', 'z', 'w',
    'r', 'g', 'b', 'a',
    's', 't', 'p', 'q',
  };
  
  UnpackFloatNode(this.node, this.component) {
    nodeType = 'UnpackFloatNode';
    
    if (!validComponents.contains(component)) {
      throw ArgumentError(
        'Invalid component: $component. '
        'Valid components: ${validComponents.join(', ')}'
      );
    }
  }
  
  @override
  void analyze(NodeBuilder builder) {
    node.build(builder, 'auto');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    String value = node.build(builder, 'auto');
    return '$value.$component';
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['node'] = node.toJSON();
    json['component'] = component;
    return json;
  }
  
  /// Create an UnpackFloatNode from JSON
  static UnpackFloatNode? fromJSON(Map<String, dynamic> json) {
    Node? node = Node.fromJSON(json['node']);
    String? component = json['component'];
    
    if (node == null || component == null) return null;
    
    return UnpackFloatNode(node, component);
  }
}

/// Node that performs bit field extraction.
/// 
/// Extracts a range of bits from an integer value.
/// 
/// Example:
/// ```dart
/// // Extract bits 4-7 from an integer
/// var extracted = BitFieldExtractNode(intNode, 4, 4);
/// ```
class BitFieldExtractNode extends Node {
  /// The value to extract bits from
  final Node valueNode;
  
  /// The offset (starting bit position)
  final Node offsetNode;
  
  /// The number of bits to extract
  final Node bitsNode;
  
  BitFieldExtractNode(this.valueNode, this.offsetNode, this.bitsNode) {
    nodeType = 'BitFieldExtractNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    valueNode.build(builder, 'auto');
    offsetNode.build(builder, 'int');
    bitsNode.build(builder, 'int');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    String value = valueNode.build(builder, 'auto');
    String offset = offsetNode.build(builder, 'int');
    String bits = bitsNode.build(builder, 'int');
    
    return 'bitfieldExtract($value, $offset, $bits)';
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['valueNode'] = valueNode.toJSON();
    json['offsetNode'] = offsetNode.toJSON();
    json['bitsNode'] = bitsNode.toJSON();
    return json;
  }
  
  /// Create a BitFieldExtractNode from JSON
  static BitFieldExtractNode? fromJSON(Map<String, dynamic> json) {
    Node? valueNode = Node.fromJSON(json['valueNode']);
    Node? offsetNode = Node.fromJSON(json['offsetNode']);
    Node? bitsNode = Node.fromJSON(json['bitsNode']);
    
    if (valueNode == null || offsetNode == null || bitsNode == null) {
      return null;
    }
    
    return BitFieldExtractNode(valueNode, offsetNode, bitsNode);
  }
}

/// Node that performs bit field insertion.
/// 
/// Inserts bits into an integer value at a specific position.
/// 
/// Example:
/// ```dart
/// // Insert bits into an integer
/// var inserted = BitFieldInsertNode(baseNode, insertNode, 4, 4);
/// ```
class BitFieldInsertNode extends Node {
  /// The base value to insert into
  final Node baseNode;
  
  /// The value to insert
  final Node insertNode;
  
  /// The offset (starting bit position)
  final Node offsetNode;
  
  /// The number of bits to insert
  final Node bitsNode;
  
  BitFieldInsertNode(
    this.baseNode,
    this.insertNode,
    this.offsetNode,
    this.bitsNode,
  ) {
    nodeType = 'BitFieldInsertNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    baseNode.build(builder, 'auto');
    insertNode.build(builder, 'auto');
    offsetNode.build(builder, 'int');
    bitsNode.build(builder, 'int');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    String base = baseNode.build(builder, 'auto');
    String insert = insertNode.build(builder, 'auto');
    String offset = offsetNode.build(builder, 'int');
    String bits = bitsNode.build(builder, 'int');
    
    return 'bitfieldInsert($base, $insert, $offset, $bits)';
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['baseNode'] = baseNode.toJSON();
    json['insertNode'] = insertNode.toJSON();
    json['offsetNode'] = offsetNode.toJSON();
    json['bitsNode'] = bitsNode.toJSON();
    return json;
  }
  
  /// Create a BitFieldInsertNode from JSON
  static BitFieldInsertNode? fromJSON(Map<String, dynamic> json) {
    Node? baseNode = Node.fromJSON(json['baseNode']);
    Node? insertNode = Node.fromJSON(json['insertNode']);
    Node? offsetNode = Node.fromJSON(json['offsetNode']);
    Node? bitsNode = Node.fromJSON(json['bitsNode']);
    
    if (baseNode == null || insertNode == null || 
        offsetNode == null || bitsNode == null) {
      return null;
    }
    
    return BitFieldInsertNode(baseNode, insertNode, offsetNode, bitsNode);
  }
}

// ============================================================================
// Convenience Functions
// ============================================================================

/// Reinterpret float bits as int
BitcastNode floatBitsToInt(Node node) => BitcastNode(node, 'int');

/// Reinterpret float bits as uint
BitcastNode floatBitsToUint(Node node) => BitcastNode(node, 'uint');

/// Reinterpret int bits as float
BitcastNode intBitsToFloat(Node node) => BitcastNode(node, 'float');

/// Count the number of set bits
BitcountNode bitCount(Node node) => BitcountNode(node);

/// Pack floats into a vector
PackFloatNode packFloat(List<Node> nodes) => PackFloatNode(nodes);

/// Unpack a component from a vector
UnpackFloatNode unpackFloat(Node node, String component) {
  return UnpackFloatNode(node, component);
}

/// Extract a bit field
BitFieldExtractNode bitfieldExtract(Node value, Node offset, Node bits) {
  return BitFieldExtractNode(value, offset, bits);
}

/// Insert a bit field
BitFieldInsertNode bitfieldInsert(
  Node base,
  Node insert,
  Node offset,
  Node bits,
) {
  return BitFieldInsertNode(base, insert, offset, bits);
}

/// Extract the x component
UnpackFloatNode extractX(Node node) => UnpackFloatNode(node, 'x');

/// Extract the y component
UnpackFloatNode extractY(Node node) => UnpackFloatNode(node, 'y');

/// Extract the z component
UnpackFloatNode extractZ(Node node) => UnpackFloatNode(node, 'z');

/// Extract the w component
UnpackFloatNode extractW(Node node) => UnpackFloatNode(node, 'w');

/// Extract the r component
UnpackFloatNode extractR(Node node) => UnpackFloatNode(node, 'r');

/// Extract the g component
UnpackFloatNode extractG(Node node) => UnpackFloatNode(node, 'g');

/// Extract the b component
UnpackFloatNode extractB(Node node) => UnpackFloatNode(node, 'b');

/// Extract the a component
UnpackFloatNode extractA(Node node) => UnpackFloatNode(node, 'a');
