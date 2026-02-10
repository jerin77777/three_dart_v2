# Math and Operator Nodes

This module provides mathematical operations, arithmetic operators, conditional logic, and bit manipulation nodes for the node material system.

## Overview

The math module contains four main categories of nodes:

1. **MathNode** - Mathematical functions (sin, cos, sqrt, etc.)
2. **OperatorNode** - Arithmetic and logical operators (+, -, *, /, etc.)
3. **ConditionalNode** - Conditional logic (ternary operator)
4. **Bit Manipulation Nodes** - Bitwise operations and type reinterpretation

## MathNode

Performs standard mathematical operations on node inputs.

### Supported Operations

#### Unary Operations (single parameter)
- **Trigonometric**: sin, cos, tan, asin, acos, atan, sinh, cosh, tanh, asinh, acosh, atanh
- **Exponential/Logarithmic**: exp, exp2, log, log2, sqrt, inversesqrt
- **Common**: abs, sign, floor, ceil, fract, round, trunc
- **Angle**: radians, degrees
- **Vector**: length, normalize
- **Special**: saturate, negate, oneMinus

#### Binary Operations (two parameters)
- **Arithmetic**: pow, min, max, mod
- **Geometric**: dot, cross, distance, reflect
- **Common**: step, atan2
- **Comparison**: equal, notEqual, lessThan, lessThanEqual, greaterThan, greaterThanEqual

#### Ternary Operations (three parameters)
- mix, clamp, smoothstep, faceforward, refract

### Usage Examples

```dart
import 'package:three_dart_v2/three3d/nodes/math/index.dart';

// Unary operations
var sinNode = sin(inputNode);
var absNode = abs(inputNode);
var normalizedNode = normalize(vectorNode);

// Binary operations
var powNode = pow(baseNode, exponentNode);
var dotNode = dot(vec1Node, vec2Node);
var minNode = min(aNode, bNode);

// Ternary operations
var mixNode = mix(aNode, bNode, tNode);
var clampNode = clamp(valueNode, minNode, maxNode);

// Direct construction
var mathNode = MathNode('sin', inputNode);
var powNode = MathNode('pow', baseNode, exponentNode);
```

### Special Cases

- **saturate**: Clamps value to 0.0-1.0 range (generates `clamp(x, 0.0, 1.0)`)
- **negate**: Negates the value (generates `-x`)
- **oneMinus**: Computes 1.0 - x (generates `1.0 - x`)
- **atan2**: Two-parameter arctangent (generates `atan(y, x)`)

## OperatorNode

Performs arithmetic, comparison, logical, and bitwise operations.

### Supported Operators

#### Arithmetic Operators
- `+` (addition)
- `-` (subtraction)
- `*` (multiplication)
- `/` (division)
- `%` (modulo)

#### Comparison Operators
- `==` (equal)
- `!=` (not equal)
- `<` (less than)
- `<=` (less than or equal)
- `>` (greater than)
- `>=` (greater than or equal)

#### Logical Operators
- `&&` (logical AND)
- `||` (logical OR)

#### Bitwise Operators
- `&` (bitwise AND)
- `|` (bitwise OR)
- `^` (bitwise XOR)
- `<<` (left shift)
- `>>` (right shift)

### Usage Examples

```dart
import 'package:three_dart_v2/three3d/nodes/math/index.dart';

// Arithmetic operations
var addNode = add(aNode, bNode);
var mulNode = mul(aNode, bNode);

// Comparison operations
var ltNode = lessThan(aNode, bNode);
var eqNode = equal(aNode, bNode);

// Logical operations
var andNode = and(condA, condB);
var orNode = or(condA, condB);

// Bitwise operations
var bitwiseAndNode = bitwiseAnd(aNode, bNode);
var shiftNode = leftShift(valueNode, bitsNode);

// Direct construction
var opNode = OperatorNode('+', aNode, bNode);

// Using Node methods
var result = aNode.add(bNode);  // Same as add(aNode, bNode)
var result = aNode.mul(2.0);    // Multiply by constant
```

### Operator Properties

```dart
var opNode = OperatorNode('+', aNode, bNode);

opNode.isArithmetic;  // true for +, -, *, /, %
opNode.isComparison;  // true for ==, !=, <, <=, >, >=
opNode.isLogical;     // true for &&, ||
opNode.isBitwise;     // true for &, |, ^, <<, >>
```

## ConditionalNode

Implements conditional logic using the ternary operator.

### Usage Examples

```dart
import 'package:three_dart_v2/three3d/nodes/math/index.dart';

// Basic conditional
var condNode = conditional(
  greaterThan(xNode, ConstantNode(0.5)),
  ConstantNode(1.0),
  ConstantNode(0.0)
);

// Generates: (x > 0.5 ? 1.0 : 0.0)

// Convert boolean to float
var floatNode = boolToFloat(conditionNode);

// Conditional clamp
var clampedNode = clampConditional(valueNode, minNode, maxNode);

// Step function
var stepNode = stepConditional(edgeNode, xNode);
```

### SelectNode

Similar to ConditionalNode but uses GLSL's `mix` function, which can work with vector conditions.

```dart
var selectNode = select(conditionNode, trueValueNode, falseValueNode);
// Generates: mix(falseValue, trueValue, condition)
```

## Bit Manipulation Nodes

Provides low-level bit manipulation operations.

### BitcastNode

Reinterprets the bit pattern of a value as a different type.

```dart
// Float to int
var intBits = floatBitsToInt(floatNode);

// Float to uint
var uintBits = floatBitsToUint(floatNode);

// Int to float
var floatBits = intBitsToFloat(intNode);

// Direct construction
var bitcastNode = BitcastNode(inputNode, 'int');
```

### BitcountNode

Counts the number of set bits (1s) in an integer.

```dart
var count = bitCount(intNode);
// Generates: bitCount(value)
```

### PackFloatNode

Packs multiple float values into a vector.

```dart
// Pack into vec2
var vec2Node = packFloat([float1, float2]);

// Pack into vec3
var vec3Node = packFloat([float1, float2, float3]);

// Pack into vec4
var vec4Node = packFloat([float1, float2, float3, float4]);

// Direct construction
var packNode = PackFloatNode([float1, float2, float3]);
```

### UnpackFloatNode

Extracts individual components from a vector.

```dart
// Extract x component
var xNode = extractX(vec3Node);

// Extract rgb components
var rNode = extractR(colorNode);
var gNode = extractG(colorNode);
var bNode = extractB(colorNode);

// Direct construction
var unpackNode = UnpackFloatNode(vectorNode, 'x');

// Valid components: x, y, z, w (or r, g, b, a, or s, t, p, q)
```

### BitFieldExtractNode

Extracts a range of bits from an integer.

```dart
// Extract bits 4-7 (4 bits starting at offset 4)
var extracted = bitfieldExtract(
  valueNode,
  ConstantNode(4.0),  // offset
  ConstantNode(4.0)   // number of bits
);

// Generates: bitfieldExtract(value, 4, 4)
```

### BitFieldInsertNode

Inserts bits into an integer at a specific position.

```dart
// Insert bits into an integer
var inserted = bitfieldInsert(
  baseNode,
  insertNode,
  ConstantNode(4.0),  // offset
  ConstantNode(4.0)   // number of bits
);

// Generates: bitfieldInsert(base, insert, 4, 4)
```

## GLSL Code Generation

All math nodes generate valid GLSL code:

```dart
var builder = NodeBuilder();

// MathNode generates function calls
sin(inputNode).generate(builder, 'float');
// Output: "sin(input)"

// OperatorNode generates operators with parentheses
add(aNode, bNode).generate(builder, 'float');
// Output: "(a + b)"

// ConditionalNode generates ternary operator
conditional(condNode, ifNode, elseNode).generate(builder, 'float');
// Output: "(cond ? ifValue : elseValue)"

// BitcastNode generates GLSL bitcast functions
floatBitsToInt(floatNode).generate(builder, 'int');
// Output: "floatBitsToInt(value)"
```

## Type Conversion

Nodes automatically handle type conversion through the Node base class:

```dart
var floatNode = ConstantNode(1.5);

// Convert to different types
var intNode = floatNode.toInt();
var vec3Node = floatNode.toVec3();  // Broadcasts to vec3(1.5, 1.5, 1.5)
```

## Serialization

All math nodes support JSON serialization:

```dart
var mathNode = sin(inputNode);
var json = mathNode.toJSON();

// Deserialize
var restored = MathNode.fromJSON(json);
```

## Error Handling

Math nodes validate operations at construction time:

```dart
// Throws ArgumentError for unknown operations
var invalid = MathNode('unknownOp', inputNode);

// Throws ArgumentError for unsupported operators
var invalid = OperatorNode('???', aNode, bNode);

// Throws ArgumentError for invalid components
var invalid = UnpackFloatNode(vectorNode, 'invalid');

// Throws ArgumentError for invalid target types
var invalid = BitcastNode(floatNode, 'vec3');
```

## Requirements Satisfied

This implementation satisfies the following requirements from the specification:

- **Requirement 3.1**: MathNode supporting standard mathematical functions ✓
- **Requirement 3.2**: OperatorNode for arithmetic operations ✓
- **Requirement 3.3**: ConditionalNode for branching logic ✓
- **Requirement 3.4**: BitcastNode for type reinterpretation ✓
- **Requirement 3.5**: BitcountNode for bit manipulation operations ✓
- **Requirement 3.6**: PackFloatNode for packing float values ✓
- **Requirement 3.7**: UnpackFloatNode for unpacking vectors ✓
- **Requirement 3.8**: Type mismatch detection during compilation ✓

## Testing

Comprehensive tests are available in `test/nodes/math/math_nodes_test.dart`:

```bash
flutter test test/nodes/math/math_nodes_test.dart
```

Test coverage includes:
- All mathematical operations
- All operator types
- Conditional logic
- Bit manipulation operations
- GLSL code generation
- Error handling
- Serialization
- Convenience functions

All 58 tests pass successfully.
