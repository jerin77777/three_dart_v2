import 'package:three_dart_v2/three3d/cameras/index.dart';
import 'package:three_dart_v2/three3d/core/index.dart';
import 'package:three_dart_v2/three3d/materials/index.dart';
import 'package:three_dart_v2/three3d/renderers/index.dart';

/// Runtime context containing per-frame data and state for node execution.
/// 
/// NodeFrame manages the execution context for a single frame, including
/// timing information, scene objects, and per-frame data storage.
class NodeFrame {
  /// Current frame ID (increments each frame)
  int frameId = 0;
  
  /// Current render ID (increments each render call)
  int renderId = 0;
  
  /// Current time in seconds
  double time = 0.0;
  
  /// Time since last frame in seconds
  double deltaTime = 0.0;
  
  /// Camera for the current render
  Camera? camera;
  
  /// Object being rendered
  Object3D? object;
  
  /// Material being used
  Material? material;
  
  /// Geometry being rendered
  BufferGeometry? geometry;
  
  /// Renderer context
  WebGLRenderer? renderer;
  
  /// Per-frame data storage
  final Map<String, dynamic> frameData = {};
  
  /// Previous frame time for delta calculation
  double _previousTime = 0.0;
  
  // ============================================================================
  // Update Methods
  // ============================================================================
  
  /// Update frame state for a new frame
  void update() {
    frameId++;
    
    // Update timing
    double currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    deltaTime = currentTime - _previousTime;
    _previousTime = currentTime;
    time = currentTime;
  }
  
  /// Update frame state for a new render
  void updateForRender() {
    renderId++;
  }
  
  /// Update frame state for rendering a specific object
  void updateForObject(Object3D obj) {
    object = obj;
    geometry = obj.geometry;
    material = obj.material is Material ? obj.material : null;
  }
  
  // ============================================================================
  // Data Access
  // ============================================================================
  
  /// Get frame data by key
  dynamic getFrameData(String key) {
    return frameData[key];
  }
  
  /// Set frame data by key
  void setFrameData(String key, dynamic value) {
    frameData[key] = value;
  }
  
  /// Check if frame data exists for a key
  bool hasFrameData(String key) {
    return frameData.containsKey(key);
  }
  
  /// Remove frame data by key
  void removeFrameData(String key) {
    frameData.remove(key);
  }
  
  /// Clear all frame data
  void clearFrameData() {
    frameData.clear();
  }
  
  // ============================================================================
  // Context Management
  // ============================================================================
  
  /// Reset the frame state
  void reset() {
    frameId = 0;
    renderId = 0;
    time = 0.0;
    deltaTime = 0.0;
    _previousTime = 0.0;
    
    camera = null;
    object = null;
    material = null;
    geometry = null;
    renderer = null;
    
    frameData.clear();
  }
  
  /// Create a snapshot of the current frame state
  Map<String, dynamic> snapshot() {
    return {
      'frameId': frameId,
      'renderId': renderId,
      'time': time,
      'deltaTime': deltaTime,
      'frameData': Map<String, dynamic>.from(frameData),
    };
  }
  
  /// Restore frame state from a snapshot
  void restore(Map<String, dynamic> snapshot) {
    frameId = snapshot['frameId'] ?? 0;
    renderId = snapshot['renderId'] ?? 0;
    time = snapshot['time'] ?? 0.0;
    deltaTime = snapshot['deltaTime'] ?? 0.0;
    
    if (snapshot['frameData'] != null) {
      frameData.clear();
      frameData.addAll(snapshot['frameData']);
    }
  }
}
