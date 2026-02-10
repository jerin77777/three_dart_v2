/// GPGPU Compute Nodes
/// 
/// This module provides nodes for GPU compute shader operations, enabling
/// general-purpose computing on the GPU (GPGPU).
/// 
/// Key components:
/// - ComputeNode: Defines compute shader operations
/// - ComputeBuiltinNode: Access to compute shader built-in variables
/// - AtomicFunctionNode: Thread-safe atomic operations
/// - BarrierNode: Synchronization between compute invocations
/// - SubgroupFunctionNode: Subgroup operations for efficient communication
/// - WorkgroupInfoNode: Access to workgroup configuration information

export 'compute_node.dart';
export 'compute_builtin_node.dart';
export 'atomic_function_node.dart';
export 'barrier_node.dart';
export 'subgroup_function_node.dart';
export 'workgroup_info_node.dart';
