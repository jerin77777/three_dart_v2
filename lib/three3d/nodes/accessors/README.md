# Accessor Nodes

Accessor nodes provide access to various data sources in the node material system. They form the input layer of the node graph, retrieving data from geometry, textures, materials, and other sources.

## Implemented Nodes

### BufferAttributeNode
Accesses vertex buffer attributes such as positions, normals, UVs, and colors.

**Usage:**
```dart
BufferAttribute positionAttr = geometry.getAttribute('position');
BufferAttributeNode positionNode = BufferAttributeNode(positionAttr, 'position');
```

**Shader Output:**
- Vertex shader: `a_position`
- Fragment shader: `v_position` (via varying)

### TextureNode
Samples 2D textures with UV coordinates and optional mipmap level control.

**Usage:**
```dart
Texture albedoTexture = Texture();
Node uvNode = BufferAttributeNode(geometry.getAttribute('uv'), 'uv');
TextureNode textureNode = TextureNode(albedoTexture, uvNode);

// With explicit mipmap level
TextureNode lodNode = TextureNode(texture, uvNode, levelNode: ConstantNode(2.0));
```

**Shader Output:**
- Standard: `texture(u_sampler, uv)`
- With LOD: `textureLod(u_sampler, uv, level)`

### CubeTextureNode
Samples cube map textures using a 3D direction vector.

**Usage:**
```dart
CubeTexture envMap = CubeTexture();
Node directionNode = reflectNode; // vec3 direction
CubeTextureNode cubeNode = CubeTextureNode(envMap, directionNode);
```

**Shader Output:**
- Standard: `texture(u_samplerCube, direction)`
- With LOD: `textureLod(u_samplerCube, direction, level)`

### MaterialNode
Accesses properties of the current material being rendered.

**Usage:**
```dart
MaterialNode colorNode = MaterialNode('color');
MaterialNode roughnessNode = MaterialNode('roughness');
MaterialNode metalnessNode = MaterialNode('metalness');
```

**Supported Properties:**
- `color`, `emissive`, `specular` → vec3
- `opacity`, `roughness`, `metalness`, `clearcoat`, etc. → float
- `normalScale`, `clearcoatNormalScale` → vec2

### MaterialReferenceNode
References properties from a different material.

**Usage:**
```dart
Material referenceMaterial = MeshStandardMaterial();
MaterialReferenceNode refNode = MaterialReferenceNode(referenceMaterial, 'color');
```

### InstanceNode
Accesses instance-specific data for instanced rendering.

**Usage:**
```dart
InstanceNode instanceColorNode = InstanceNode('color');
InstanceNode instanceMatrixNode = InstanceNode('matrix');
```

**Shader Output:**
- `instance_color`
- `instance_matrix`

### InstancedMeshNode
Specialized accessor for InstancedMesh data.

**Usage:**
```dart
InstancedMeshNode matrixNode = InstancedMeshNode('instanceMatrix');
InstancedMeshNode colorNode = InstancedMeshNode('instanceColor');
```

**Shader Output:**
- Instance matrix: `mat4(instanceMatrix0, instanceMatrix1, instanceMatrix2, instanceMatrix3)`
- Instance color: `instanceColor`

### ModelNode
Accesses model transformation matrices and related data.

**Usage:**
```dart
ModelNode modelMatrixNode = ModelNode('modelMatrix');
ModelNode normalMatrixNode = ModelNode('normalMatrix');
ModelNode modelViewMatrixNode = ModelNode('modelViewMatrix');
```

**Supported Data Types:**
- `modelMatrix`, `modelViewMatrix`, `projectionMatrix`, `viewMatrix` → mat4
- `normalMatrix` → mat3
- `position`, `scale` → vec3
- `rotation` → vec4 (quaternion)

### Object3DNode
Accesses properties of 3D objects.

**Usage:**
```dart
Object3DNode positionNode = Object3DNode('position');
Object3DNode scaleNode = Object3DNode('scale');

// Reference specific object
Object3D specificObject = Object3D();
Object3DNode refNode = Object3DNode('worldPosition', object: specificObject);
```

**Supported Properties:**
- `position`, `scale`, `worldPosition` → vec3
- `rotation`, `quaternion` → vec4
- `matrix`, `matrixWorld` → mat4
- `visible` → bool
- `id` → int

### Storage Buffer Nodes (Compute Shaders)

#### StorageBufferNode
Declares and accesses GPU storage buffers for compute shaders.

**Usage:**
```dart
StorageBufferNode particleBuffer = StorageBufferNode('particles', 'vec4');
StorageBufferNode readOnlyBuffer = StorageBufferNode('data', 'float', readOnly: true);
```

#### StorageBufferElementNode
Accesses individual elements in a storage buffer.

**Usage:**
```dart
StorageBufferNode buffer = StorageBufferNode('data', 'vec4');
Node indexNode = ConstantNode(5);
StorageBufferElementNode element = StorageBufferElementNode(buffer, indexNode);
```

**Shader Output:**
- `data[5]`

#### StorageTextureNode
Declares storage textures for compute shader read/write operations.

**Usage:**
```dart
StorageTextureNode outputTexture = StorageTextureNode('outputTex', 'rgba8');
StorageTextureNode inputTexture = StorageTextureNode('inputTex', 'rgba8', readOnly: true);
```

**Supported Formats:**
- `rgba8`, `rgba16f`, `rgba32f`
- `r32f`, `rg32f`
- And other image formats

#### StorageTextureReadNode
Reads from a storage texture.

**Usage:**
```dart
StorageTextureNode texture = StorageTextureNode('inputTex', 'rgba8', readOnly: true);
Node coordNode = Vec2Node(10, 20);
StorageTextureReadNode readNode = StorageTextureReadNode(texture, coordNode);
```

**Shader Output:**
- `imageLoad(inputTex, ivec2(10, 20))`

#### StorageTextureWriteNode
Writes to a storage texture.

**Usage:**
```dart
StorageTextureNode texture = StorageTextureNode('outputTex', 'rgba8');
Node coordNode = Vec2Node(10, 20);
Node valueNode = Vec4Node(1.0, 0.0, 0.0, 1.0);
StorageTextureWriteNode writeNode = StorageTextureWriteNode(texture, coordNode, valueNode);
```

**Shader Output:**
- `imageStore(outputTex, ivec2(10, 20), vec4(1.0, 0.0, 0.0, 1.0));`

## Design Patterns

### Context Requirements
Some accessor nodes require specific context to be available in the NodeBuilder:

- **MaterialNode**: Requires `builder.material` to be set
- **ModelNode**: Requires `builder.object` to be set
- **Object3DNode**: Requires `builder.object` to be set (unless specific object provided)
- **Storage nodes**: Require `builder.shaderStage == 'compute'`

### Type System
Accessor nodes automatically determine their output type based on the data they access:

- Buffer attributes: Based on `itemSize` (1→float, 2→vec2, 3→vec3, 4→vec4)
- Textures: Always vec4 (RGBA)
- Material properties: Based on property type
- Matrices: mat3 or mat4
- Vectors: vec2, vec3, or vec4

### Uniform Generation
Most accessor nodes create uniforms automatically:

```dart
String uniformName = builder.getUniformFromNode(this, type);
```

This ensures:
- Unique uniform names per node
- Proper type declarations
- Automatic uniform value updates

## Testing

All accessor nodes have comprehensive unit tests covering:
- Node creation and configuration
- GLSL code generation
- Context validation
- Error handling
- JSON serialization

Run tests:
```bash
flutter test test/nodes/accessors/accessor_test.dart
```

## Requirements Satisfied

This implementation satisfies the following requirements from the design document:

- **Requirement 2.1**: BufferAttributeNode for vertex buffer attribute access
- **Requirement 2.2**: TextureNode for 2D texture sampling
- **Requirement 2.3**: CubeTextureNode for cube map sampling
- **Requirement 2.4**: MaterialNode for material property access
- **Requirement 2.5**: MaterialReferenceNode for referencing other materials
- **Requirement 2.6**: InstanceNode for instance-specific data
- **Requirement 2.7**: InstancedMeshNode for instanced mesh rendering
- **Requirement 2.8**: ModelNode for model transformation data
- **Requirement 2.9**: Object3DNode for 3D object properties
- **Requirement 2.10**: Storage buffer nodes for compute shader data access
- **Requirement 2.11**: Storage texture nodes for read-write texture operations

## Next Steps

With accessor nodes complete, the next phase is to implement:
1. Math and operator nodes (Task 6)
2. Code and function nodes (Task 7)
3. Display and output nodes (Task 9)
4. Lighting system nodes (Task 10)

These will build upon the accessor nodes to create complete material graphs.

