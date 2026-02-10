/// Lighting system nodes for the node material system.
/// 
/// This module provides nodes for computing lighting contributions from
/// various light types, as well as shadow mapping, ambient occlusion,
/// and environment-based lighting.
library;

// Core lighting infrastructure
export 'lighting_model.dart';
export 'physical_lighting_model.dart';
export 'lighting_context_node.dart';

// Light-specific nodes
export 'ambient_light_node.dart';
export 'directional_light_node.dart';
export 'point_light_node.dart';
export 'spot_light_node.dart';
export 'rect_area_light_node.dart';

// Shadow and environment nodes
export 'shadow_node.dart';
export 'ao_node.dart';
export 'environment_node.dart';
export 'irradiance_node.dart';
