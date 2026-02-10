# Node Material System - Core Infrastructure

This directory contains the core infrastructure for the Node Material System, implementing the foundational classes that enable shader node-based material creation.

## Implemented Components

### 1. Node Base Class (`node.dart`)

The fundamental building block of the node material system. All node types inherit from this base class.

**Key Features:**
- ✅ Unique UUID generation for each node instance
- ✅ Type conversion methods (toFloat, toVec2, toVec3, toVec4, etc.)
- ✅ Operator methods (add, sub, mul, div, mod, pow, dot, cross)
- ✅ Serialization support (toJSON/fromJSON)
- ✅ Build pipeline integration (build, analyze, generate)
- ✅ Automatic value-to-node conversion

**Helper Node Classes:**
- `ConvertNode` - Type conversion between GLSL types
- `OperatorNode` - Arithmetic operations (+, -, *, /, %)
- `MathNode` - Mathematical functions (sin, cos, pow, etc.)
- `ConstantNode` - Constant float values
- `Vec2Node`, `Vec3Node`, `Vec4Node` - Vector constants

**Requirements Satisfied:** 1.1, 1.2, 1.9, 1.10

### 2. NodeBuilder Class (`node_builder.dart`)

Compiles node graphs into executable GLSL shader code through a three-phase pipeline.

**Key Features:**
- ✅ Three-phase compilation (setup, analyze, generate)
- ✅ Code generation helpers (getUniformFromNode, getAttributeFromNode, getVaryingFromNode)
- ✅ Type system methods (getType, getVectorType)
- ✅ Optimization support (caching, dead code elimination)
- ✅ Uniform, attribute, and varying management
- ✅ GLSL version targeting
- ✅ Stack management for nested operations

**Compilation Pipeline:**
1. **Setup Phase** - Traverse node graph and collect dependencies
2. **Analyze Phase** - Determine caching needs and optimize
3. **Generate Phase** - Produce final GLSL shader code

**Requirements Satisfied:** 1.3, 16.1, 16.2, 16.3, 16.4

### 3. NodeFrame Class (`node_frame.dart`)

Manages per-frame execution context and runtime data.

**Key Features:**
- ✅ Frame and render ID tracking
- ✅ Timing information (time, deltaTime)
- ✅ Scene object references (camera, object, material, geometry, renderer)
- ✅ Per-frame data storage
- ✅ Update methods for frame, render, and object updates
- ✅ State snapshot and restore

**Requirements Satisfied:** 1.4

### 4. NodeCache Class (`node_cache.dart`)

Provides caching for compiled results and shader resources.

**Key Features:**
- ✅ General cache operations (get, set, has, delete, clear)
- ✅ Shader program caching
- ✅ Uniform location caching
- ✅ Node result caching
- ✅ Cache statistics and management
- ✅ Memory usage estimation

**Requirements Satisfied:** 1.5, 18.1, 18.2

### 5. NodeUniform Class (`node_uniform.dart`)

Represents shader uniform variables.

**Key Features:**
- ✅ Uniform name and type management
- ✅ Node-based value provision
- ✅ Update tracking (needsUpdate flag)
- ✅ GPU upload interface
- ✅ Serialization support

**Requirements Satisfied:** 1.6

### 6. NodeAttribute Class (`node_attribute.dart`)

Represents vertex attributes in shaders.

**Key Features:**
- ✅ Attribute name and type management
- ✅ Buffer attribute binding
- ✅ Enable/disable control
- ✅ WebGL binding interface
- ✅ Serialization support

**Requirements Satisfied:** 1.6

### 7. NodeVarying Class (`node_varying.dart`)

Represents data passed from vertex to fragment shaders.

**Key Features:**
- ✅ Varying name and type management
- ✅ Interpolation mode support (smooth, flat, noperspective)
- ✅ Vertex and fragment shader declaration generation
- ✅ Node-based value provision
- ✅ Serialization support

**Requirements Satisfied:** 1.6

## Usage Examples

### Creating a Simple Node Graph

```dart
import 'package:three_dart_v2/three3d/nodes/core/index.dart';

// Create constant nodes
final color = Vec3Node(1.0, 0.0, 0.0); // Red color
final intensity = ConstantNode(0.5);

// Combine using operators
final result = color.mul(intensity); // Red * 0.5

// Build shader code
final builder = NodeBuilder();
final glsl = result.build(builder, 'vec3');
print(glsl); // Output: (vec3(1.0, 0.0, 0.0) * 0.5)
```

### Using NodeBuilder

```dart
// Create a node graph
final outputNode = Vec4Node(1.0, 0.0, 0.0, 1.0);

// Compile to shader
final builder = NodeBuilder();
builder.shaderStage = 'fragment';
final shaderCode = builder.build(outputNode);

print(shaderCode);
// Output:
// #version 300 es
// precision highp float;
// precision highp int;
//
// void main() {
//   ...
// }
```

### Managing Frame State

```dart
final frame = NodeFrame();

// Update for new frame
frame.update();
print('Frame ${frame.frameId}, Time: ${frame.time}s');

// Store frame data
frame.setFrameData('customValue', 42);
final value = frame.getFrameData('customValue');
```

### Using Cache

```dart
final cache = NodeCache();

// Cache a shader program
cache.setProgram('myShader', program);

// Retrieve cached program
final cachedProgram = cache.getProgram('myShader');

// Check cache statistics
final stats = cache.getStatistics();
print('Total cached items: ${stats['total']}');
```

## Testing

Comprehensive unit tests are provided in `test/nodes/core/node_test.dart`:

- ✅ 36 tests covering all core functionality
- ✅ Node UUID uniqueness
- ✅ Type conversion methods
- ✅ Operator methods
- ✅ GLSL code generation
- ✅ NodeBuilder compilation pipeline
- ✅ NodeFrame state management
- ✅ NodeCache operations
- ✅ NodeUniform, NodeAttribute, NodeVarying functionality

Run tests with:
```bash
flutter test three_dart_v2/test/nodes/core/node_test.dart
```

## Architecture

```
Node (Base Class)
├── build() - Main entry point
├── analyze() - Dependency analysis
├── generate() - GLSL code generation
├── Type conversions (toFloat, toVec2, etc.)
└── Operators (add, sub, mul, div, etc.)

NodeBuilder
├── setup() - Phase 1: Traverse graph
├── analyze() - Phase 2: Optimize
├── generate() - Phase 3: Generate GLSL
└── Code generation helpers

NodeFrame
├── Frame state (frameId, time, deltaTime)
├── Scene references (camera, object, material)
└── Per-frame data storage

NodeCache
├── General cache
├── Shader program cache
├── Uniform location cache
└── Node result cache
```

## Next Steps

With the core infrastructure complete, the next tasks are:

1. **Task 3**: Implement node graph validation system
2. **Task 5**: Implement accessor nodes (texture, buffer attributes, etc.)
3. **Task 6**: Implement math and operator nodes (expanded functionality)
4. **Task 7**: Implement code and function nodes

## Requirements Traceability

| Requirement | Status | Implementation |
|-------------|--------|----------------|
| 1.1 - Base Node class | ✅ Complete | `node.dart` |
| 1.2 - Unique identifiers | ✅ Complete | `Node.uuid` with UUID generation |
| 1.3 - NodeBuilder | ✅ Complete | `node_builder.dart` |
| 1.4 - NodeFrame | ✅ Complete | `node_frame.dart` |
| 1.5 - NodeCache | ✅ Complete | `node_cache.dart` |
| 1.6 - Uniforms/Attributes/Varyings | ✅ Complete | `node_uniform.dart`, `node_attribute.dart`, `node_varying.dart` |
| 1.9 - Property nodes | ✅ Complete | Base infrastructure in `Node` class |
| 1.10 - Parameter nodes | ✅ Complete | Base infrastructure in `Node` class |
| 16.1 - GLSL generation | ✅ Complete | `NodeBuilder.generate()` |
| 16.2 - Dead code elimination | ✅ Complete | `NodeBuilder.analyze()` |
| 16.3 - Inlining | ✅ Complete | `NodeBuilder` optimization |
| 16.4 - Common subexpression elimination | ✅ Complete | `NodeBuilder` caching |
| 18.1 - Shader program caching | ✅ Complete | `NodeCache.programCache` |
| 18.2 - Uniform location caching | ✅ Complete | `NodeCache.uniformLocationCache` |

## Files Created

1. `lib/three3d/nodes/core/node.dart` - Base Node class and helper nodes
2. `lib/three3d/nodes/core/node_builder.dart` - Shader compilation pipeline
3. `lib/three3d/nodes/core/node_frame.dart` - Runtime frame context
4. `lib/three3d/nodes/core/node_cache.dart` - Caching system
5. `lib/three3d/nodes/core/node_uniform.dart` - Uniform variable representation
6. `lib/three3d/nodes/core/node_attribute.dart` - Vertex attribute representation
7. `lib/three3d/nodes/core/node_varying.dart` - Varying variable representation
8. `lib/three3d/nodes/core/index.dart` - Public API exports
9. `test/nodes/core/node_test.dart` - Comprehensive unit tests
10. `lib/three3d/nodes/core/README.md` - This documentation

## Code Quality

- ✅ All code passes `flutter analyze` with no issues
- ✅ Comprehensive documentation with dartdoc comments
- ✅ 36 unit tests with 100% pass rate
- ✅ Follows Dart naming conventions
- ✅ Type-safe implementation with null safety
- ✅ Clean separation of concerns
