# Display and Output Nodes

This directory contains nodes for display operations, color management, and shader output in the node material system.

## Overview

Display nodes handle the final stages of rendering, including color space conversion, tone mapping, normal mapping, and output to render targets. These nodes are essential for achieving correct color reproduction and realistic surface detail.

## Implemented Nodes

### Color Management

#### ColorSpaceNode
Converts colors between different color spaces (sRGB, linear, Display P3).

**Key Features:**
- Accurate sRGB ↔ linear conversion using proper gamma curves
- Display P3 color space support
- Preserves color accuracy for physically-based rendering

**Example:**
```dart
// Convert sRGB texture to linear for lighting calculations
Node colorNode = TextureNode(albedoTexture, uvNode);
ColorSpaceNode linearColor = ColorSpaceNode(
  colorNode,
  sourceColorSpace: 'srgb',
  targetColorSpace: 'linear'
);
```

#### ToneMappingNode
Applies tone mapping to HDR colors for display.

**Supported Algorithms:**
- Linear: Simple exposure multiplication
- Reinhard: Classic Reinhard tone mapping
- Cineon: Filmic tone mapping
- ACES: Academy Color Encoding System (industry standard)
- AgX: Modern tone mapping with good color preservation
- Neutral: Khronos PBR Neutral tone mapper

**Example:**
```dart
// Apply ACES tone mapping with exposure control
Node hdrColor = LightingNode(...);
ToneMappingNode toneMapped = ToneMappingNode(
  hdrColor,
  toneMappingType: 'aces',
  exposureNode: FloatNode(1.2)
);
```

### Surface Detail

#### NormalMapNode
Applies normal mapping to perturb surface normals.

**Key Features:**
- Tangent space normal mapping (default)
- Object space normal mapping support
- Adjustable normal intensity scaling
- Automatic TBN matrix construction

**Example:**
```dart
// Apply normal map with custom scale
Node normalTexture = TextureNode(normalMap, uvNode);
NormalMapNode normalNode = NormalMapNode(
  normalTexture,
  scaleNode: Vec2Node(1.0, 1.0)
);
```

#### BumpMapNode
Derives normals from height maps (bump mapping).

**Key Features:**
- Height-based normal perturbation
- Adjustable bump intensity
- Screen-space derivative calculation

**Example:**
```dart
// Apply bump mapping from height texture
Node heightTexture = TextureNode(bumpMap, uvNode);
BumpMapNode bumpNode = BumpMapNode(
  heightTexture,
  scaleNode: FloatNode(0.5)
);
```

### Screen-Space Operations

#### ScreenNode
Provides screen-space coordinates and information.

**Output Modes:**
- `uv`: Screen UV coordinates [0,1]
- `coordinate`: Screen pixel coordinates
- `viewport`: Viewport size
- `size`: Screen size in pixels

**Example:**
```dart
// Get screen UV coordinates for viewport sampling
ScreenNode screenUV = ScreenNode(mode: 'uv');

// Get viewport size for calculations
ScreenNode viewportSize = ScreenNode(mode: 'viewport');
```

#### ViewportTextureNode
Samples from the viewport/screen texture.

**Use Cases:**
- Screen-space reflections
- Refraction effects
- Post-processing effects
- UI overlays

**Example:**
```dart
// Sample viewport for refraction effect
Node screenUV = ScreenNode();
ViewportTextureNode refraction = ViewportTextureNode(
  screenUV,
  levelNode: FloatNode(0.0)
);
```

### Output

#### RenderOutputNode
Defines shader output to render targets.

**Key Features:**
- Single render target output
- Multiple render target (MRT) support
- Custom output names
- Automatic output declaration

**Example:**
```dart
// Simple color output
RenderOutputNode output = RenderOutputNode(
  finalColorNode,
  outputName: 'fragColor'
);

// Multiple render targets
RenderOutputNode colorOut = colorOutput(colorNode, index: 0);
RenderOutputNode normalOut = normalOutput(normalNode, index: 1);
RenderOutputNode positionOut = positionOutput(positionNode, index: 2);
```

## Color Space Workflow

Proper color space handling is critical for physically-based rendering:

1. **Input Textures**: Convert sRGB textures to linear space
   ```dart
   Node albedo = ColorSpaceNode(
     TextureNode(albedoTexture, uvNode),
     sourceColorSpace: 'srgb',
     targetColorSpace: 'linear'
   );
   ```

2. **Lighting Calculations**: Perform all lighting in linear space
   ```dart
   Node lighting = PhysicalLightingNode(albedo, normal, ...);
   ```

3. **Tone Mapping**: Map HDR to LDR
   ```dart
   Node toneMapped = ToneMappingNode(
     lighting,
     toneMappingType: 'aces',
     exposureNode: exposure
   );
   ```

4. **Output**: Convert to display color space if needed
   ```dart
   Node output = ColorSpaceNode(
     toneMapped,
     sourceColorSpace: 'linear',
     targetColorSpace: 'srgb'
   );
   ```

## Normal Mapping Workflow

Normal mapping adds surface detail without additional geometry:

1. **Load Normal Map**: Sample the normal map texture
   ```dart
   Node normalTexture = TextureNode(normalMap, uvNode);
   ```

2. **Apply Normal Mapping**: Convert to world-space normals
   ```dart
   Node normal = NormalMapNode(
     normalTexture,
     scaleNode: Vec2Node(1.0, 1.0)
   );
   ```

3. **Use in Lighting**: Pass to lighting calculations
   ```dart
   Node lighting = PhysicalLightingNode(
     albedo,
     normal,  // Use perturbed normal
     ...
   );
   ```

## Screen-Space Effects

Screen-space operations enable advanced effects:

### Refraction Example
```dart
// Get screen coordinates
Node screenUV = ScreenNode(mode: 'uv');

// Offset by refraction
Node refractionOffset = MulNode(normalNode, FloatNode(0.1));
Node refractedUV = AddNode(screenUV, refractionOffset);

// Sample viewport
Node refractedColor = ViewportTextureNode(refractedUV);
```

### Screen-Space Reflection Example
```dart
// Calculate reflection vector in screen space
Node viewDir = normalize(cameraPosition - worldPosition);
Node reflectDir = reflect(viewDir, normalNode);

// Convert to screen UV
Node reflectionUV = worldToScreen(reflectDir);

// Sample viewport
Node reflection = ViewportTextureNode(reflectionUV);
```

## Multiple Render Targets (MRT)

Output to multiple textures simultaneously:

```dart
// Define outputs
RenderOutputNode colorOut = RenderOutputNode(
  finalColor,
  outputName: 'fragColor',
  outputIndex: 0,
  outputType: 'vec4'
);

RenderOutputNode normalOut = RenderOutputNode(
  worldNormal,
  outputName: 'fragNormal',
  outputIndex: 1,
  outputType: 'vec4'
);

RenderOutputNode positionOut = RenderOutputNode(
  worldPosition,
  outputName: 'fragPosition',
  outputIndex: 2,
  outputType: 'vec4'
);

// Use in deferred rendering or post-processing
```

## Implementation Status

✅ **Completed:**
- ColorSpaceNode (sRGB, linear, Display P3)
- ToneMappingNode (6 algorithms)
- NormalMapNode (tangent and object space)
- BumpMapNode (height-based)
- ScreenNode (4 output modes)
- ViewportTextureNode
- RenderOutputNode (single and MRT)

## Testing

Display nodes should be tested for:
- Color space conversion accuracy (round-trip tests)
- Tone mapping output ranges [0,1]
- Normal map tangent space correctness
- Screen coordinate calculations
- MRT output declaration

## Requirements Satisfied

- **5.1**: ColorSpaceNode for color space conversions ✅
- **5.2**: ToneMappingNode for HDR tone mapping ✅
- **5.3**: NormalMapNode for normal mapping ✅
- **5.4**: BumpMapNode for bump mapping ✅
- **5.5**: ViewportTextureNode for viewport access ✅
- **5.6**: ScreenNode for screen-space operations ✅
- **5.7**: RenderOutputNode for shader outputs ✅
- **5.8**: Multiple render target support ✅
- **5.9**: Color accuracy preservation ✅

## Next Steps

The display nodes are complete. Next tasks:
- Task 10: Implement lighting system nodes
- Property tests for color space round-trip (Property 6)
- Integration tests with material system
