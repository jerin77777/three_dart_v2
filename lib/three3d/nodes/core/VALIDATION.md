# Node Graph Validation System

## Overview

The node graph validation system provides comprehensive validation of node graphs before compilation, catching errors early and providing helpful error messages with suggestions for fixes.

## Components

### ValidationError

A class representing validation errors with detailed context:

- **Message**: Human-readable description of the error
- **Node**: Reference to the problematic node
- **Severity**: 'error' or 'warning'
- **Suggestion**: Actionable advice for fixing the issue
- **Context**: Additional metadata about the error

#### Factory Methods

- `ValidationError.typeMismatch()` - Type incompatibility between nodes
- `ValidationError.circularDependency()` - Circular reference in graph
- `ValidationError.missingInput()` - Required input not connected
- `ValidationError.disconnectedOutput()` - Node output not used
- `ValidationError.shaderCompilation()` - Shader compilation failure
- `ValidationError.unsupportedFeature()` - Platform feature not available

### NodeGraphValidator

The main validation class that performs comprehensive graph analysis:

#### Validation Checks

1. **Type Compatibility**: Ensures connected nodes have compatible types
2. **Circular Dependencies**: Detects cycles in the node graph using DFS
3. **Missing Inputs**: Checks for required inputs that aren't connected
4. **Disconnected Outputs**: Warns about unused node outputs

#### Usage

```dart
// Create a validator
NodeGraphValidator validator = NodeGraphValidator();

// Validate a node graph
List<ValidationError> errors = validator.validate(rootNode);

// Check for critical errors
List<ValidationError> criticalErrors = errors
    .where((e) => e.severity == 'error')
    .toList();

if (criticalErrors.isNotEmpty) {
  // Handle errors
  for (var error in criticalErrors) {
    print(error.toString());
  }
}

// Or validate and throw on error
try {
  validator.validateOrThrow(rootNode);
} on NodeValidationException catch (e) {
  print(e.toString());
}
```

## Error Examples

### Type Mismatch

```
[error] Type mismatch: Cannot connect TextureNode output (vec4) to MathNode.sin input (float)
  Node: MathNode(uuid: abc12345)
  Suggestion: Use .x, .y, .z, or .w to extract a single component, or use a SplitNode
```

### Circular Dependency

```
[error] Circular dependency detected in node graph
  Node: MulNode(uuid: def45678)
  Suggestion: Remove one of the connections to break the cycle: MulNode(def45678) → AddNode(ghi78901) → MulNode(def45678)
```

### Missing Input

```
[error] Required input 'texture' not connected on TextureNode
  Node: TextureNode(uuid: jkl01234)
  Suggestion: Connect a sampler2D node to the 'texture' input
```

### Disconnected Output

```
[warning] Node OperatorNode output is not connected to anything
  Node: OperatorNode(uuid: mno34567)
  Suggestion: Connect this node to another node or remove it from the graph
```

## Integration with NodeBuilder

The validation system integrates with the NodeBuilder compilation pipeline:

```dart
class NodeBuilder {
  String build(Node? outputNode) {
    // Validate before compilation
    NodeGraphValidator validator = NodeGraphValidator();
    List<ValidationError> errors = validator.validate(outputNode);
    
    // Filter critical errors
    List<ValidationError> criticalErrors = errors
        .where((e) => e.severity == 'error')
        .toList();
    
    if (criticalErrors.isNotEmpty) {
      throw NodeValidationException(criticalErrors);
    }
    
    // Proceed with compilation
    setup(outputNode);
    analyze();
    return generate();
  }
}
```

## Type Compatibility Rules

The validator uses the following type compatibility rules:

1. **Exact Match**: Same types are always compatible
2. **Auto Type**: 'auto' accepts any type
3. **Numeric Conversion**: Numeric types can be converted (float, int, uint, vectors)
4. **Vector Family**: Vector types of the same family are compatible (vec2, vec3, vec4)

## Circular Dependency Detection

Uses depth-first search (DFS) with a recursion stack to detect cycles:

1. Traverse the graph starting from the root node
2. Track visited nodes and current recursion path
3. If a node in the recursion stack is encountered again, a cycle exists
4. Reconstruct the cycle path for error reporting

## Future Enhancements

- **Required Input Metadata**: Node types can declare required inputs
- **Custom Validation Rules**: Extensible validation for custom node types
- **Performance Optimization**: Cache validation results for unchanged graphs
- **Visual Error Highlighting**: Integration with graph visualization tools

## Testing

Comprehensive test coverage in `test/nodes/core/node_graph_validator_test.dart`:

- Basic validation scenarios
- Circular dependency detection
- Type compatibility checking
- Error message formatting
- Exception handling
- Edge cases and warnings

Run tests:
```bash
flutter test test/nodes/core/node_graph_validator_test.dart
```
