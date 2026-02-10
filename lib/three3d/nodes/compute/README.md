# GPGPU Compute Nodes

This module provides nodes for GPU compute shader operations, enabling general-purpose computing on the GPU (GPGPU).

## Overview

Compute shaders allow you to perform parallel computations on the GPU outside the traditional vertex/fragment rendering pipeline. This is useful for:
- Physics simulations
- Particle systems
- Image processing
- Data transformations
- Scientific computing

## Components

### ComputeNode

Defines a compute shader operation with configurable workgroup size.

```dart
ComputeNode compute = ComputeNode(
  computeLogicNode,
  workgroupSize: [8, 8, 1],
  count: 1024
);
```

### ComputeBuiltinNode

Provides access to compute shader built-in variables:
- `gl_GlobalInvocationID`: Global work item ID
- `gl_LocalInvocationID`: Local work item ID within workgroup
- `gl_WorkGroupID`: Work group ID
- `gl_LocalInvocationIndex`: 1D index of local invocation
- `gl_NumWorkGroups`: Number of work groups

```dart
ComputeBuiltinNode globalId = ComputeBuiltinNode.globalInvocationID();
ComputeBuiltinNode localId = ComputeBuiltinNode.localInvocationID();
```

### AtomicFunctionNode

Performs thread-safe atomic operations on shared memory:
- `add`: Atomic addition
- `sub`: Atomic subtraction
- `max`: Atomic maximum
- `min`: Atomic minimum
- `and`: Atomic bitwise AND
- `or`: Atomic bitwise OR
- `xor`: Atomic bitwise XOR
- `exchange`: Atomic exchange
- `compSwap`: Atomic compare-and-swap

```dart
AtomicFunctionNode atomicAdd = AtomicFunctionNode.add(
  storageBufferNode,
  valueNode
);
```

### BarrierNode

Provides synchronization between compute shader invocations:
- `workgroup`: Synchronizes all invocations in a workgroup
- `memory`: Memory barrier for shared memory
- `buffer`: Memory barrier for buffer memory
- `image`: Memory barrier for image memory

```dart
BarrierNode barrier = BarrierNode.workgroup();
```

### SubgroupFunctionNode

Provides efficient subgroup operations:
- `barrier`: Subgroup barrier
- `elect`: Returns true for one invocation in the subgroup
- `all`: Returns true if value is true for all invocations
- `any`: Returns true if value is true for any invocation
- `broadcast`: Broadcast value from one invocation to all
- `add`: Sum values across subgroup
- `mul`: Multiply values across subgroup
- `min`: Minimum value across subgroup
- `max`: Maximum value across subgroup

```dart
SubgroupFunctionNode sum = SubgroupFunctionNode.add(valueNode);
```

### WorkgroupInfoNode

Provides access to workgroup configuration:
- `size`: Workgroup size
- `subgroupSize`: Size of subgroups
- `numSubgroups`: Number of subgroups
- `subgroupID`: Current subgroup ID

```dart
WorkgroupInfoNode workgroupSize = WorkgroupInfoNode.size();
```

## Example: Particle System

```dart
// Get global invocation ID
ComputeBuiltinNode globalId = ComputeBuiltinNode.globalInvocationID();

// Access particle data from storage buffer
StorageBufferNode particleBuffer = StorageBufferNode('particles');

// Update particle position
Node updateLogic = CodeNode('''
  uint index = ${globalId.generate(builder, 'uvec3')}.x;
  vec3 position = particles[index].position;
  vec3 velocity = particles[index].velocity;
  
  // Update position
  position += velocity * deltaTime;
  
  // Write back
  particles[index].position = position;
''');

// Create compute shader
ComputeNode compute = ComputeNode(
  updateLogic,
  workgroupSize: [256, 1, 1],
  count: numParticles ~/ 256
);
```

## Platform Support

Compute shaders require:
- OpenGL 4.3+ or OpenGL ES 3.1+
- WebGL 2.0 Compute (limited support)

The system will detect platform capabilities and provide appropriate fallbacks or error messages when compute shaders are not supported.

## Requirements Satisfied

- **7.1**: ComputeNode for defining compute shader operations
- **7.2**: ComputeBuiltinNode for accessing compute shader built-in variables
- **7.3**: AtomicFunctionNode for atomic operations on shared memory
- **7.4**: BarrierNode for synchronization between compute threads
- **7.5**: SubgroupFunctionNode for subgroup operations
- **7.6**: WorkgroupInfoNode for accessing workgroup information
- **7.7**: Compute shader support where available
- **7.8**: Fallback behavior for unsupported platforms
