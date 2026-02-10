/// Storage system for reusing compiled node results and avoiding redundant computations.
/// 
/// NodeCache provides caching for:
/// - Compiled shader programs
/// - Uniform locations
/// - Node computation results
/// - Material compilation state
class NodeCache {
  /// Main cache storage
  final Map<String, dynamic> _cache = {};
  
  /// Shader program cache
  final Map<String, dynamic> _programCache = {};
  
  /// Uniform location cache
  final Map<String, dynamic> _uniformLocationCache = {};
  
  /// Node result cache
  final Map<String, dynamic> _nodeResultCache = {};
  
  // ============================================================================
  // General Cache Operations
  // ============================================================================
  
  /// Get a value from the cache
  dynamic get(String key) {
    return _cache[key];
  }
  
  /// Set a value in the cache
  void set(String key, dynamic value) {
    _cache[key] = value;
  }
  
  /// Check if a key exists in the cache
  bool has(String key) {
    return _cache.containsKey(key);
  }
  
  /// Delete a value from the cache
  void delete(String key) {
    _cache.remove(key);
  }
  
  /// Clear all cache entries
  void clear() {
    _cache.clear();
    _programCache.clear();
    _uniformLocationCache.clear();
    _nodeResultCache.clear();
  }
  
  // ============================================================================
  // Shader Program Cache
  // ============================================================================
  
  /// Get a cached shader program
  dynamic getProgram(String key) {
    return _programCache[key];
  }
  
  /// Cache a shader program
  void setProgram(String key, dynamic program) {
    _programCache[key] = program;
  }
  
  /// Check if a shader program is cached
  bool hasProgram(String key) {
    return _programCache.containsKey(key);
  }
  
  /// Delete a cached shader program
  void deleteProgram(String key) {
    _programCache.remove(key);
  }
  
  /// Clear all cached shader programs
  void clearPrograms() {
    _programCache.clear();
  }
  
  /// Get the number of cached programs
  int get programCount => _programCache.length;
  
  // ============================================================================
  // Uniform Location Cache
  // ============================================================================
  
  /// Get a cached uniform location
  dynamic getUniformLocation(String key) {
    return _uniformLocationCache[key];
  }
  
  /// Cache a uniform location
  void setUniformLocation(String key, dynamic location) {
    _uniformLocationCache[key] = location;
  }
  
  /// Check if a uniform location is cached
  bool hasUniformLocation(String key) {
    return _uniformLocationCache.containsKey(key);
  }
  
  /// Delete a cached uniform location
  void deleteUniformLocation(String key) {
    _uniformLocationCache.remove(key);
  }
  
  /// Clear all cached uniform locations
  void clearUniformLocations() {
    _uniformLocationCache.clear();
  }
  
  /// Get the number of cached uniform locations
  int get uniformLocationCount => _uniformLocationCache.length;
  
  // ============================================================================
  // Node Result Cache
  // ============================================================================
  
  /// Get a cached node result
  dynamic getNodeResult(String nodeId) {
    return _nodeResultCache[nodeId];
  }
  
  /// Cache a node result
  void setNodeResult(String nodeId, dynamic result) {
    _nodeResultCache[nodeId] = result;
  }
  
  /// Check if a node result is cached
  bool hasNodeResult(String nodeId) {
    return _nodeResultCache.containsKey(nodeId);
  }
  
  /// Delete a cached node result
  void deleteNodeResult(String nodeId) {
    _nodeResultCache.remove(nodeId);
  }
  
  /// Clear all cached node results
  void clearNodeResults() {
    _nodeResultCache.clear();
  }
  
  /// Get the number of cached node results
  int get nodeResultCount => _nodeResultCache.length;
  
  // ============================================================================
  // Cache Statistics
  // ============================================================================
  
  /// Get total number of cached items
  int get totalCount => 
      _cache.length + 
      _programCache.length + 
      _uniformLocationCache.length + 
      _nodeResultCache.length;
  
  /// Get cache statistics
  Map<String, int> getStatistics() {
    return {
      'general': _cache.length,
      'programs': _programCache.length,
      'uniformLocations': _uniformLocationCache.length,
      'nodeResults': _nodeResultCache.length,
      'total': totalCount,
    };
  }
  
  // ============================================================================
  // Cache Management
  // ============================================================================
  
  /// Clear cache entries older than the specified duration
  void clearOlderThan(Duration duration) {
    // This would require timestamp tracking for each entry
    // For now, we'll just clear everything
    // TODO: Implement timestamp-based cache eviction
    clear();
  }
  
  /// Limit cache size by removing oldest entries
  void limitSize(int maxEntries) {
    // Simple implementation: clear if over limit
    // TODO: Implement LRU cache eviction
    if (totalCount > maxEntries) {
      clear();
    }
  }
  
  /// Get memory usage estimate (in bytes)
  int estimateMemoryUsage() {
    // Rough estimate - would need more sophisticated calculation
    return totalCount * 1024; // Assume 1KB per entry on average
  }
}
