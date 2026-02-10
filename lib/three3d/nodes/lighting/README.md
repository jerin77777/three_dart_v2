# Lighting System Nodes

This module implements the lighting system for the node material system, providing nodes for computing lighting contributions from various light sources and environmental effects.

## Overview

The lighting system consists of:

1. **Lighting Models**: Define how light interacts with surfaces (Lambert, Phong, PBR)
2. **Light Nodes**: Compute contributions from specific light types
3. **Shadow Nodes**: Handle shadow mapping and soft shadows
4. **Environment Nodes**: Provide image-based lighting (IBL)
5. **Context Nodes**: Access lighting-related data (position, normal, view direction)

## Components

### Lighting Models

#### LightingModel (Base Class)
Abstract base class that defines the interface for lighting calculations:
- `direct()`: Compute direct lighting from light sources
- `indirect()`: Compute indirect lighting from environment
- `ambientOcclusion()`: Compute AO factor
- `finish()`: Post-process lighting result

#### LambertLightingModel
Simple diffuse lighting using Lambert's cosine law. Suitable for matte surfaces.

```dart
LambertLightingModel model = LambertLightingModel();
```

#### PhongLightingModel
Phong shading with diffuse and specular components.

```dart
PhongLightingModel model = PhongLightingModel(
  shininess: 30.0,
  specularColor: ConstantNode(1.0).toVec3(),
);
```

#### PhysicalLightingModel
Full PBR (Physically Based Rendering) with Cook-Torrance BRDF:
- Fresnel effect (Schlick approximation)
- GGX normal distribution
- Smith geometry function
- Image-based lighting (IBL)

```dart
PhysicalLightingModel model = PhysicalLightingModel(
  albedo: albedoNode,
  roughness: roughnessNode,
  metalness: metalnessNode,
  environmentMap: envMapNode,
  irradianceMap: irradianceNode,
);
```

### Light Nodes

#### AmbientLightNode
Provides uniform ambient illumination from all directions.

```dart
AmbientLightNode ambient = AmbientLightNode(ambientLight);
```

#### DirectionalLightNode
Computes lighting from directional lights (parallel rays, like sunlight).

```dart
DirectionalLightNode directional = DirectionalLightNode(
  light: directionalLight,
  lightingModel: model,
  normalNode: normalNode,
  viewDirectionNode: viewDirNode,
  materialNode: materialNode,
);
```

#### PointLightNode
Computes lighting from point lights with distance attenuation.

```dart
PointLightNode point = PointLightNode(
  light: pointLight,
  lightingModel: model,
  worldPositionNode: worldPosNode,
  normalNode: normalNode,
  viewDirectionNode: viewDirNode,
  materialNode: materialNode,
);
```

#### SpotLightNode
Computes lighting from spot lights with cone attenuation and soft edges.

```dart
SpotLightNode spot = SpotLightNode(
  light: spotLight,
  lightingModel: model,
  worldPositionNode: worldPosNode,
  normalNode: normalNode,
  viewDirectionNode: viewDirNode,
  materialNode: materialNode,
);
```

#### RectAreaLightNode
Computes lighting from rectangular area lights (more realistic architectural lighting).

```dart
RectAreaLightNode rectArea = RectAreaLightNode(
  light: rectAreaLight,
  lightingModel: model,
  worldPositionNode: worldPosNode,
  normalNode: normalNode,
  viewDirectionNode: viewDirNode,
  materialNode: materialNode,
);
```

### Shadow and Environment Nodes

#### ShadowNode
Samples shadow maps to determine if a surface is in shadow.

```dart
ShadowNode shadow = ShadowNode(
  light: light,
  worldPositionNode: worldPosNode,
  usePCF: true,  // Use soft shadows
  pcfRadius: 1.0,
);
```

#### AONode
Provides ambient occlusion from texture or screen-space AO.

```dart
// Texture-based AO
AONode ao = AONode(
  aoTexture: aoTexture,
  uvNode: uvNode,
  intensity: 1.0,
);

// Screen-space AO
AONode ssao = AONode(
  useSSAO: true,
  intensity: 1.0,
);
```

#### EnvironmentNode
Samples environment maps for reflections and refractions.

```dart
EnvironmentNode env = EnvironmentNode(
  cubeTexture: envMap,
  directionNode: reflectionDir,
  roughnessNode: roughnessNode,  // For roughness-based mip selection
  maxMipLevel: 5,
  intensity: 1.0,
);
```

#### IrradianceNode
Samples pre-convolved irradiance maps for diffuse indirect lighting.

```dart
IrradianceNode irradiance = IrradianceNode(
  irradianceMap: irradianceMap,
  normalNode: normalNode,
  intensity: 1.0,
);
```

### Context Nodes

#### LightingContextNode
Provides access to lighting-related data:

```dart
// World position
WorldPositionNode worldPos = WorldPositionNode();

// World normal
WorldNormalNode worldNormal = WorldNormalNode();

// View direction (surface to camera)
ViewDirectionNode viewDir = ViewDirectionNode();

// Normal
NormalNode normal = NormalNode();

// UV coordinates
UVNode uv = UVNode();

// Vertex color
VertexColorNode color = VertexColorNode();
```

## Usage Example

### Basic Lighting Setup

```dart
// Create lighting model
PhysicalLightingModel model = PhysicalLightingModel(
  albedo: texture(albedoMap),
  roughness: ConstantNode(0.5),
  metalness: ConstantNode(0.0),
);

// Get context nodes
WorldPositionNode worldPos = WorldPositionNode();
WorldNormalNode normal = WorldNormalNode();
ViewDirectionNode viewDir = ViewDirectionNode();

// Create light nodes
DirectionalLightNode sun = DirectionalLightNode(
  light: sunLight,
  lightingModel: model,
  normalNode: normal,
  viewDirectionNode: viewDir,
  materialNode: materialPropsNode,
);

PointLightNode lamp = PointLightNode(
  light: lampLight,
  lightingModel: model,
  worldPositionNode: worldPos,
  normalNode: normal,
  viewDirectionNode: viewDir,
  materialNode: materialPropsNode,
);

// Add shadows
ShadowNode sunShadow = ShadowNode(
  light: sunLight,
  worldPositionNode: worldPos,
  usePCF: true,
);

// Combine lighting
Node totalLighting = sun.mul(sunShadow).add(lamp);
```

### PBR with IBL

```dart
// Create PBR model with environment maps
PhysicalLightingModel pbrModel = PhysicalLightingModel(
  albedo: texture(albedoMap),
  roughness: texture(roughnessMap),
  metalness: texture(metalnessMap),
  environmentMap: envCubeMap,
  irradianceMap: irradianceCubeMap,
  aoNode: AONode(aoTexture: aoMap, uvNode: UVNode()),
);

// Get context
WorldNormalNode normal = WorldNormalNode();
ViewDirectionNode viewDir = ViewDirectionNode();

// Compute direct lighting from lights
Node directLighting = computeDirectLighting(lights, pbrModel);

// Compute indirect lighting from environment
LightingContext indirectContext = LightingContext(
  lightDirection: ConstantNode(0.0).toVec3(),
  lightColor: ConstantNode(0.0).toVec3(),
  viewDirection: viewDir,
  normal: normal,
  material: materialNode,
);

Node indirectLighting = pbrModel.indirect(indirectContext);

// Combine
Node finalColor = directLighting.add(indirectLighting);
```

## Implementation Notes

### Lighting Accumulation

When multiple lights are present, their contributions should be accumulated:

```dart
Node totalLighting = ConstantNode(0.0).toVec3();

for (Light light in lights) {
  Node lightContribution = createLightNode(light, model);
  totalLighting = totalLighting.add(lightContribution);
}
```

### Shadow Integration

Shadows are applied by multiplying the light contribution:

```dart
Node lightContribution = lightNode;
if (light.castShadow) {
  ShadowNode shadow = ShadowNode(light: light, worldPositionNode: worldPos);
  lightContribution = lightContribution.mul(shadow);
}
```

### Performance Considerations

1. **Light Count**: Each light adds shader instructions. Consider using light culling for scenes with many lights.

2. **Shadow Quality**: PCF shadows are more expensive than hard shadows. Adjust `pcfRadius` based on quality needs.

3. **IBL Complexity**: Full PBR with IBL requires multiple texture samples. Consider simpler models for mobile.

4. **Shader Compilation**: Light nodes generate shader code at compile time. The system automatically optimizes unused lights.

## Requirements Satisfied

This implementation satisfies the following requirements:

- **6.1**: AmbientLightNode for ambient lighting
- **6.2**: DirectionalLightNode for directional lights
- **6.3**: PointLightNode for point lights
- **6.4**: SpotLightNode for spotlights
- **6.5**: RectAreaLightNode for area lights
- **6.6**: ShadowNode for shadow mapping
- **6.7**: AONode for ambient occlusion
- **6.8**: EnvironmentNode for environment maps
- **6.9**: IrradianceNode for irradiance
- **6.10**: LightingModel interface and PhysicalLightingModel
- **6.11**: LightingContextNode for context data
- **6.12**: Proper lighting accumulation (handled by node composition)

## Testing

See `test/nodes/lighting/` for unit tests covering:
- Lighting model calculations
- Light node code generation
- Shadow sampling
- Environment map sampling
- Context node access

## Future Enhancements

Potential improvements for future versions:

1. **Clustered/Tiled Lighting**: For scenes with many lights
2. **Light Probes**: For dynamic indirect lighting
3. **Volumetric Lighting**: For fog and atmospheric effects
4. **Subsurface Scattering**: For translucent materials
5. **Anisotropic Lighting**: For brushed metal and fabric
6. **Clear Coat**: For car paint and lacquered surfaces
