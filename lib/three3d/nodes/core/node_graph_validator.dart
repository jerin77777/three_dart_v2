import 'node.dart';
import 'node_builder.dart';
import 'validation_error.dart';

/// Validates node graphs for correctness before compilation.
/// 
/// Performs comprehensive validation including:
/// - Type compatibility between connected nodes
/// - Circular dependency detection
/// - Missing required input detection
/// - Disconnected output detection
class NodeGraphValidator {
  /// Validate a node graph starting from the root node
  /// 
  /// Returns a list of validation errors. An empty list means the graph is valid.
  List<ValidationError> validate(Node? rootNode) {
    if (rootNode == null) {
      return [
        ValidationError(
          message: 'Root node is null',
          severity: 'error',
          suggestion: 'Provide a valid root node for validation',
        ),
      ];
    }
    
    List<ValidationError> errors = [];
    
    // Collect all nodes in the graph
    Set<Node> allNodes = <Node>{};
    Map<Node, List<Node>> dependencies = {};
    _collectNodes(rootNode, allNodes, dependencies);
    
    // Check for circular dependencies
    errors.addAll(_detectCircularDependencies(allNodes, dependencies));
    
    // Check type compatibility
    errors.addAll(_validateTypeCompatibility(allNodes, dependencies));
    
    // Check for missing required inputs
    errors.addAll(_validateRequiredInputs(allNodes));
    
    // Check for disconnected outputs (warnings only)
    errors.addAll(_validateConnectedOutputs(allNodes, dependencies));
    
    return errors;
  }
  
  /// Collect all nodes in the graph and their dependencies
  void _collectNodes(
    Node node,
    Set<Node> allNodes,
    Map<Node, List<Node>> dependencies,
  ) {
    if (allNodes.contains(node)) {
      return; // Already visited
    }
    
    allNodes.add(node);
    
    // Get dependencies for this node
    List<Node> nodeDeps = _getNodeDependencies(node);
    dependencies[node] = nodeDeps;
    
    // Recursively collect dependencies
    for (var dep in nodeDeps) {
      _collectNodes(dep, allNodes, dependencies);
    }
  }
  
  /// Get direct dependencies of a node
  List<Node> _getNodeDependencies(Node node) {
    List<Node> deps = [];
    
    // Check common node types for dependencies
    if (node is ConvertNode) {
      deps.add(node.node);
    } else if (node is OperatorNode) {
      deps.add(node.aNode);
      deps.add(node.bNode);
    } else if (node is MathNode) {
      deps.add(node.aNode);
      if (node.bNode != null) deps.add(node.bNode!);
      if (node.cNode != null) deps.add(node.cNode!);
    }
    
    // For other node types, we would need to inspect their properties
    // This will be extended as more node types are implemented
    
    return deps;
  }
  
  /// Detect circular dependencies in the node graph
  List<ValidationError> _detectCircularDependencies(
    Set<Node> allNodes,
    Map<Node, List<Node>> dependencies,
  ) {
    List<ValidationError> errors = [];
    
    // Use depth-first search to detect cycles
    Set<Node> visited = <Node>{};
    Set<Node> recursionStack = <Node>{};
    Map<Node, Node?> parent = {};
    
    for (var node in allNodes) {
      if (!visited.contains(node)) {
        List<Node>? cycle = _detectCycleDFS(
          node,
          visited,
          recursionStack,
          parent,
          dependencies,
        );
        
        if (cycle != null) {
          errors.add(ValidationError.circularDependency(cycle: cycle));
        }
      }
    }
    
    return errors;
  }
  
  /// Depth-first search to detect cycles
  List<Node>? _detectCycleDFS(
    Node node,
    Set<Node> visited,
    Set<Node> recursionStack,
    Map<Node, Node?> parent,
    Map<Node, List<Node>> dependencies,
  ) {
    visited.add(node);
    recursionStack.add(node);
    
    List<Node> deps = dependencies[node] ?? [];
    
    for (var dep in deps) {
      parent[dep] = node;
      
      if (!visited.contains(dep)) {
        List<Node>? cycle = _detectCycleDFS(
          dep,
          visited,
          recursionStack,
          parent,
          dependencies,
        );
        if (cycle != null) return cycle;
      } else if (recursionStack.contains(dep)) {
        // Found a cycle - reconstruct it
        return _reconstructCycle(dep, node, parent);
      }
    }
    
    recursionStack.remove(node);
    return null;
  }
  
  /// Reconstruct the cycle path
  List<Node> _reconstructCycle(Node start, Node end, Map<Node, Node?> parent) {
    List<Node> cycle = [end];
    Node? current = end;
    
    while (current != null && current != start) {
      current = parent[current];
      if (current != null) {
        cycle.insert(0, current);
      }
    }
    
    cycle.add(start); // Complete the cycle
    return cycle;
  }
  
  /// Validate type compatibility between connected nodes
  List<ValidationError> _validateTypeCompatibility(
    Set<Node> allNodes,
    Map<Node, List<Node>> dependencies,
  ) {
    List<ValidationError> errors = [];
    
    // Create a temporary builder for type checking
    NodeBuilder builder = NodeBuilder();
    
    for (var node in allNodes) {
      List<Node> deps = dependencies[node] ?? [];
      
      // Check type compatibility for each dependency
      for (var dep in deps) {
        String sourceType = builder.getType(dep);
        String targetType = _getExpectedInputType(node, dep);
        
        if (targetType != 'auto' && !_areTypesCompatible(sourceType, targetType)) {
          errors.add(ValidationError.typeMismatch(
            sourceNode: dep,
            sourceType: sourceType,
            targetNode: node,
            targetType: targetType,
            inputName: _getInputName(node, dep),
          ));
        }
      }
    }
    
    return errors;
  }
  
  /// Get the expected input type for a node's dependency
  String _getExpectedInputType(Node node, Node dependency) {
    // For most nodes, we accept 'auto' (any type)
    // Specific nodes may have stricter requirements
    
    if (node is ConvertNode) {
      return 'auto'; // Conversion accepts any type
    } else if (node is OperatorNode) {
      return 'auto'; // Operators work with compatible types
    } else if (node is MathNode) {
      // Math functions may have specific requirements
      return _getMathFunctionInputType(node.method);
    }
    
    return 'auto';
  }
  
  /// Get expected input type for math functions
  String _getMathFunctionInputType(String method) {
    // Functions that require specific types
    switch (method) {
      case 'dot':
      case 'cross':
      case 'length':
      case 'normalize':
        return 'vec'; // Any vector type
      case 'sin':
      case 'cos':
      case 'tan':
      case 'asin':
      case 'acos':
      case 'atan':
      case 'exp':
      case 'log':
      case 'sqrt':
      case 'abs':
      case 'floor':
      case 'ceil':
      case 'fract':
        return 'auto'; // Works with float or vector
      default:
        return 'auto';
    }
  }
  
  /// Get the input name for a dependency
  String? _getInputName(Node node, Node dependency) {
    if (node is ConvertNode && node.node == dependency) {
      return 'input';
    } else if (node is OperatorNode) {
      if (node.aNode == dependency) return 'a';
      if (node.bNode == dependency) return 'b';
    } else if (node is MathNode) {
      if (node.aNode == dependency) return 'a';
      if (node.bNode == dependency) return 'b';
      if (node.cNode == dependency) return 'c';
    }
    return null;
  }
  
  /// Check if two types are compatible
  bool _areTypesCompatible(String sourceType, String targetType) {
    // Same type is always compatible
    if (sourceType == targetType) return true;
    
    // 'auto' accepts any type
    if (targetType == 'auto') return true;
    
    // Numeric types can be converted
    if (_isNumericType(sourceType) && _isNumericType(targetType)) {
      return true;
    }
    
    // Vector types of same family are compatible
    if (_isVectorType(sourceType) && targetType == 'vec') {
      return true;
    }
    
    return false;
  }
  
  bool _isNumericType(String type) {
    return type == 'float' || type == 'int' || type == 'uint' ||
           _isVectorType(type);
  }
  
  bool _isVectorType(String type) {
    return type.startsWith('vec') || type.startsWith('ivec') ||
           type.startsWith('uvec') || type.startsWith('bvec');
  }
  
  /// Validate that all required inputs are connected
  List<ValidationError> _validateRequiredInputs(Set<Node> allNodes) {
    List<ValidationError> errors = [];
    
    // For now, we don't have a way to mark inputs as required
    // This will be implemented as more node types are added
    // Each node type would need to declare its required inputs
    
    return errors;
  }
  
  /// Validate that all outputs are connected (warnings only)
  List<ValidationError> _validateConnectedOutputs(
    Set<Node> allNodes,
    Map<Node, List<Node>> dependencies,
  ) {
    List<ValidationError> errors = [];
    
    // Find nodes that are not dependencies of any other node
    Set<Node> usedNodes = <Node>{};
    for (var deps in dependencies.values) {
      usedNodes.addAll(deps);
    }
    
    for (var node in allNodes) {
      if (!usedNodes.contains(node)) {
        // This node's output is not used
        // Only warn for non-constant nodes
        if (node is! ConstantNode &&
            node is! Vec2Node &&
            node is! Vec3Node &&
            node is! Vec4Node) {
          errors.add(ValidationError.disconnectedOutput(node: node));
        }
      }
    }
    
    return errors;
  }
  
  /// Validate a node graph and throw an exception if invalid
  void validateOrThrow(Node? rootNode) {
    List<ValidationError> errors = validate(rootNode);
    
    // Filter out warnings
    List<ValidationError> criticalErrors = errors
        .where((e) => e.severity == 'error')
        .toList();
    
    if (criticalErrors.isNotEmpty) {
      throw NodeValidationException(criticalErrors);
    }
  }
}
