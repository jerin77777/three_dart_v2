# Function Nodes

This module provides nodes for embedding custom shader code and defining reusable functions.

## Components

### CodeNode
Embeds raw GLSL code with placeholder substitution.

**Example:**
```dart
CodeNode customCode = CodeNode(
  'vec3 result = mix(\${colorA}, \${colorB}, \${factor});',
  includes: {
    'colorA': colorNodeA,
    'colorB': colorNodeB,
    'factor': factorNode,
  }
);
```

### ExpressionNode
Represents inline shader expressions for simple operations.

**Example:**
```dart
ExpressionNode expr = ExpressionNode(
  'smoothstep(\${edge0}, \${edge1}, \${x})',
  includes: {
    'edge0': edge0Node,
    'edge1': edge1Node,
    'x': xNode,
  }
);
```

### FunctionNode
Defines reusable shader functions with parameters and return types.

**Example:**
```dart
FunctionNode customLighting = FunctionNode(
  name: 'calculateLighting',
  parameters: [
    FunctionParameter(name: 'normal', type: 'vec3'),
    FunctionParameter(name: 'lightDir', type: 'vec3'),
    FunctionParameter(name: 'lightColor', type: 'vec3'),
  ],
  returnType: 'vec3',
  bodyNode: CodeNode('return lightColor * max(dot(normal, lightDir), 0.0);'),
);
```

### FunctionCallNode
Invokes defined functions with argument validation.

**Example:**
```dart
FunctionCallNode call = FunctionCallNode(
  functionNode: customLighting,
  arguments: [normalNode, lightDirNode, lightColorNode],
);
```

## Features

- **Raw Code Embedding**: Inject custom GLSL code directly
- **Placeholder Substitution**: Dynamic value insertion from other nodes
- **Function Definitions**: Create reusable shader functions
- **Parameter Validation**: Automatic type and count checking
- **Type Safety**: Validates argument types match parameter requirements

## Requirements Satisfied

- **4.1**: CodeNode for embedding raw shader code
- **4.2**: ExpressionNode for inline shader expressions
- **4.3**: FunctionNode for defining reusable shader functions
- **4.4**: FunctionCallNode for invoking defined functions
- **4.5**: Parameter validation for function calls

## Implementation Status

✅ CodeNode - Complete
✅ ExpressionNode - Complete
✅ FunctionNode - Complete
✅ FunctionCallNode - Complete
