import '../core/node.dart';
import '../core/node_builder.dart';

/// Node that accesses an element from an array.
/// 
/// Generates GLSL array indexing syntax. Supports both constant
/// and dynamic indices.
/// 
/// Example:
/// ```dart
/// // Access array element: array[index]
/// var elementNode = ArrayElementNode(arrayNode, indexNode);
/// 
/// // Access with constant index: array[2]
/// var elementNode = ArrayElementNode(arrayNode, ConstantNode(2));
/// ```
class ArrayElementNode extends Node {
  /// The array node to index into
  final Node arrayNode;
  
  /// The index node (can be constant or dynamic)
  final Node indexNode;
  
  ArrayElementNode(this.arrayNode, this.indexNode) {
    nodeType = 'ArrayElementNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    arrayNode.build(builder, 'auto');
    indexNode.build(builder, 'int');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    String array = arrayNode.build(builder, 'auto');
    String index = indexNode.build(builder, 'int');
    
    // Generate array access
    return '$array[$index]';
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['arrayNode'] = arrayNode.toJSON();
    json['indexNode'] = indexNode.toJSON();
    return json;
  }
  
  /// Create an ArrayElementNode from JSON
  static ArrayElementNode? fromJSON(Map<String, dynamic> json) {
    Node? arrayNode = Node.fromJSON(json['arrayNode']);
    Node? indexNode = Node.fromJSON(json['indexNode']);
    
    if (arrayNode == null || indexNode == null) return null;
    
    return ArrayElementNode(arrayNode, indexNode);
  }
}

/// Node that represents an array literal.
/// 
/// Creates an array from a list of elements.
/// 
/// Example:
/// ```dart
/// // Create array: float[3](1.0, 2.0, 3.0)
/// var arrayNode = ArrayNode([
///   ConstantNode(1.0),
///   ConstantNode(2.0),
///   ConstantNode(3.0),
/// ], elementType: 'float');
/// ```
class ArrayNode extends Node {
  /// Elements in the array
  final List<Node> elements;
  
  /// Type of array elements
  final String elementType;
  
  ArrayNode(this.elements, {required this.elementType}) {
    nodeType = 'ArrayNode';
    
    if (elements.isEmpty) {
      throw ArgumentError('ArrayNode requires at least one element');
    }
  }
  
  @override
  void analyze(NodeBuilder builder) {
    for (var element in elements) {
      element.build(builder, elementType);
    }
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    List<String> values = elements.map((e) => e.build(builder, elementType)).toList();
    int length = elements.length;
    
    // Generate array constructor
    return '$elementType[$length](${values.join(', ')})';
  }
  
  /// Get the length of the array
  int get length => elements.length;
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['elements'] = elements.map((e) => e.toJSON()).toList();
    json['elementType'] = elementType;
    return json;
  }
  
  /// Create an ArrayNode from JSON
  static ArrayNode? fromJSON(Map<String, dynamic> json) {
    List<dynamic>? elementsJson = json['elements'];
    String? elementType = json['elementType'];
    
    if (elementsJson == null || elementType == null) return null;
    
    List<Node> elements = [];
    for (var elementJson in elementsJson) {
      Node? element = Node.fromJSON(elementJson);
      if (element != null) {
        elements.add(element);
      }
    }
    
    if (elements.isEmpty) return null;
    
    return ArrayNode(elements, elementType: elementType);
  }
}

/// Node that gets the length of an array.
/// 
/// Returns the compile-time length of an array.
/// 
/// Example:
/// ```dart
/// // Get array length
/// var lengthNode = ArrayLengthNode(arrayNode);
/// ```
class ArrayLengthNode extends Node {
  /// The array node to get length from
  final Node arrayNode;
  
  ArrayLengthNode(this.arrayNode) {
    nodeType = 'ArrayLengthNode';
  }
  
  @override
  void analyze(NodeBuilder builder) {
    arrayNode.build(builder, 'auto');
  }
  
  @override
  String generate(NodeBuilder builder, String output) {
    // For GLSL arrays, length is a compile-time constant
    // If the array is an ArrayNode, we can get its length directly
    if (arrayNode is ArrayNode) {
      return '${(arrayNode as ArrayNode).length}';
    }
    
    // Otherwise, use .length() method (GLSL 4.3+)
    String array = arrayNode.build(builder, 'auto');
    return '$array.length()';
  }
  
  @override
  Map<String, dynamic> toJSON() {
    Map<String, dynamic> json = super.toJSON();
    json['arrayNode'] = arrayNode.toJSON();
    return json;
  }
  
  /// Create an ArrayLengthNode from JSON
  static ArrayLengthNode? fromJSON(Map<String, dynamic> json) {
    Node? arrayNode = Node.fromJSON(json['arrayNode']);
    if (arrayNode == null) return null;
    
    return ArrayLengthNode(arrayNode);
  }
}

// ============================================================================
// Convenience Functions
// ============================================================================

/// Access array element at index
ArrayElementNode arrayElement(Node array, Node index) => 
  ArrayElementNode(array, index);

/// Create an array from elements
ArrayNode array(List<Node> elements, {required String elementType}) => 
  ArrayNode(elements, elementType: elementType);

/// Get array length
ArrayLengthNode arrayLength(Node array) => ArrayLengthNode(array);
