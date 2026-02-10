// GPGPU compute node tests
// Tests for ComputeNode, ComputeBuiltinNode, AtomicFunctionNode, etc.

import 'package:flutter_test/flutter_test.dart';
import 'package:three_dart_v2/three3d/nodes/compute/index.dart';
import 'package:three_dart_v2/three3d/nodes/core/node.dart';
import 'package:three_dart_v2/three3d/nodes/core/node_builder.dart';
import 'package:three_dart_v2/three3d/nodes/functions/code_node.dart';

void main() {
  group('ComputeNode', () {
    test('creates compute node with default workgroup size', () {
      Node logic = CodeNode('// compute logic');
      ComputeNode compute = ComputeNode(logic);
      
      expect(compute.nodeType, 'ComputeNode');
      expect(compute.workgroupSize, [1, 1, 1]);
      expect(compute.count, 1);
    });
    
    test('creates compute node with custom workgroup size', () {
      Node logic = CodeNode('// compute logic');
      ComputeNode compute = ComputeNode(
        logic,
        workgroupSize: [8, 8, 1],
        count: 256
      );
      
      expect(compute.workgroupSize, [8, 8, 1]);
      expect(compute.count, 256);
    });
    
    test('validates workgroup size length', () {
      Node logic = CodeNode('// compute logic');
      
      expect(
        () => ComputeNode(logic, workgroupSize: [8, 8]),
        throwsArgumentError
      );
    });
    
    test('validates workgroup size values', () {
      Node logic = CodeNode('// compute logic');
      
      expect(
        () => ComputeNode(logic, workgroupSize: [0, 8, 1]),
        throwsArgumentError
      );
    });
    
    test('validates count value', () {
      Node logic = CodeNode('// compute logic');
      
      expect(
        () => ComputeNode(logic, count: 0),
        throwsArgumentError
      );
    });
    
    test('builds compute shader with layout declaration', () {
      Node logic = CodeNode('// compute logic');
      ComputeNode compute = ComputeNode(
        logic,
        workgroupSize: [16, 16, 1]
      );
      
      NodeBuilder builder = NodeBuilder();
      builder.shaderStage = 'compute';
      
      String result = compute.build(builder, 'void');
      
      // Verify the build completed without errors
      expect(result, isNotNull);
    });
    
    test('serializes to JSON', () {
      Node logic = CodeNode('// compute logic');
      ComputeNode compute = ComputeNode(
        logic,
        workgroupSize: [8, 8, 1],
        count: 128
      );
      
      Map<String, dynamic> json = compute.toJSON();
      
      expect(json['type'], 'ComputeNode');
      expect(json['workgroupSize'], [8, 8, 1]);
      expect(json['count'], 128);
      expect(json['computeNode'], isNotNull);
    });
  });
  
  group('ComputeBuiltinNode', () {
    test('creates builtin node for gl_GlobalInvocationID', () {
      ComputeBuiltinNode node = ComputeBuiltinNode('gl_GlobalInvocationID');
      
      expect(node.nodeType, 'ComputeBuiltinNode');
      expect(node.builtinName, 'gl_GlobalInvocationID');
      expect(node.getBuiltinType(), 'uvec3');
    });
    
    test('creates builtin node for gl_LocalInvocationID', () {
      ComputeBuiltinNode node = ComputeBuiltinNode('gl_LocalInvocationID');
      
      expect(node.builtinName, 'gl_LocalInvocationID');
      expect(node.getBuiltinType(), 'uvec3');
    });
    
    test('creates builtin node for gl_WorkGroupID', () {
      ComputeBuiltinNode node = ComputeBuiltinNode('gl_WorkGroupID');
      
      expect(node.builtinName, 'gl_WorkGroupID');
      expect(node.getBuiltinType(), 'uvec3');
    });
    
    test('creates builtin node for gl_LocalInvocationIndex', () {
      ComputeBuiltinNode node = ComputeBuiltinNode('gl_LocalInvocationIndex');
      
      expect(node.builtinName, 'gl_LocalInvocationIndex');
      expect(node.getBuiltinType(), 'uint');
    });
    
    test('creates builtin node for gl_NumWorkGroups', () {
      ComputeBuiltinNode node = ComputeBuiltinNode('gl_NumWorkGroups');
      
      expect(node.builtinName, 'gl_NumWorkGroups');
      expect(node.getBuiltinType(), 'uvec3');
    });
    
    test('rejects invalid builtin name', () {
      expect(
        () => ComputeBuiltinNode('invalid_builtin'),
        throwsArgumentError
      );
    });
    
    test('generates correct GLSL in compute stage', () {
      ComputeBuiltinNode node = ComputeBuiltinNode('gl_GlobalInvocationID');
      NodeBuilder builder = NodeBuilder();
      builder.shaderStage = 'compute';
      
      String glsl = node.generate(builder, 'uvec3');
      
      expect(glsl, 'gl_GlobalInvocationID');
    });
    
    test('throws error when used outside compute stage', () {
      ComputeBuiltinNode node = ComputeBuiltinNode('gl_GlobalInvocationID');
      NodeBuilder builder = NodeBuilder();
      builder.shaderStage = 'fragment';
      
      expect(
        () => node.generate(builder, 'uvec3'),
        throwsStateError
      );
    });
    
    test('convenience factory methods work', () {
      expect(ComputeBuiltinNode.globalInvocationID().builtinName, 'gl_GlobalInvocationID');
      expect(ComputeBuiltinNode.localInvocationID().builtinName, 'gl_LocalInvocationID');
      expect(ComputeBuiltinNode.workGroupID().builtinName, 'gl_WorkGroupID');
      expect(ComputeBuiltinNode.localInvocationIndex().builtinName, 'gl_LocalInvocationIndex');
      expect(ComputeBuiltinNode.numWorkGroups().builtinName, 'gl_NumWorkGroups');
    });
    
    test('serializes to JSON', () {
      ComputeBuiltinNode node = ComputeBuiltinNode('gl_GlobalInvocationID');
      Map<String, dynamic> json = node.toJSON();
      
      expect(json['type'], 'ComputeBuiltinNode');
      expect(json['builtinName'], 'gl_GlobalInvocationID');
    });
  });
  
  group('AtomicFunctionNode', () {
    late Node pointerNode;
    late Node valueNode;
    
    setUp(() {
      pointerNode = CodeNode('buffer[index]');
      valueNode = CodeNode('1');
    });
    
    test('creates atomic add operation', () {
      AtomicFunctionNode node = AtomicFunctionNode(
        'add',
        pointerNode: pointerNode,
        valueNode: valueNode
      );
      
      expect(node.nodeType, 'AtomicFunctionNode');
      expect(node.operation, 'add');
    });
    
    test('creates atomic sub operation', () {
      AtomicFunctionNode node = AtomicFunctionNode(
        'sub',
        pointerNode: pointerNode,
        valueNode: valueNode
      );
      
      expect(node.operation, 'sub');
    });
    
    test('creates atomic max operation', () {
      AtomicFunctionNode node = AtomicFunctionNode(
        'max',
        pointerNode: pointerNode,
        valueNode: valueNode
      );
      
      expect(node.operation, 'max');
    });
    
    test('creates atomic compSwap operation', () {
      Node compareNode = CodeNode('0');
      AtomicFunctionNode node = AtomicFunctionNode(
        'compSwap',
        pointerNode: pointerNode,
        valueNode: valueNode,
        compareNode: compareNode
      );
      
      expect(node.operation, 'compSwap');
      expect(node.compareNode, isNotNull);
    });
    
    test('rejects invalid operation', () {
      expect(
        () => AtomicFunctionNode(
          'invalid',
          pointerNode: pointerNode,
          valueNode: valueNode
        ),
        throwsArgumentError
      );
    });
    
    test('requires compareNode for compSwap', () {
      expect(
        () => AtomicFunctionNode(
          'compSwap',
          pointerNode: pointerNode,
          valueNode: valueNode
        ),
        throwsArgumentError
      );
    });
    
    test('generates correct GLSL for add operation', () {
      AtomicFunctionNode node = AtomicFunctionNode(
        'add',
        pointerNode: pointerNode,
        valueNode: valueNode
      );
      
      NodeBuilder builder = NodeBuilder();
      builder.shaderStage = 'compute';
      
      String glsl = node.generate(builder, 'int');
      
      expect(glsl, contains('atomicAdd'));
    });
    
    test('generates correct GLSL for sub operation', () {
      AtomicFunctionNode node = AtomicFunctionNode(
        'sub',
        pointerNode: pointerNode,
        valueNode: valueNode
      );
      
      NodeBuilder builder = NodeBuilder();
      builder.shaderStage = 'compute';
      
      String glsl = node.generate(builder, 'int');
      
      // Sub uses atomicAdd with negated value
      expect(glsl, contains('atomicAdd'));
      expect(glsl, contains('-('));
    });
    
    test('throws error when used outside compute stage', () {
      AtomicFunctionNode node = AtomicFunctionNode(
        'add',
        pointerNode: pointerNode,
        valueNode: valueNode
      );
      
      NodeBuilder builder = NodeBuilder();
      builder.shaderStage = 'fragment';
      
      expect(
        () => node.generate(builder, 'int'),
        throwsStateError
      );
    });
    
    test('convenience factory methods work', () {
      expect(AtomicFunctionNode.atomicAdd(pointerNode, valueNode).operation, 'add');
      expect(AtomicFunctionNode.atomicSub(pointerNode, valueNode).operation, 'sub');
      expect(AtomicFunctionNode.atomicMax(pointerNode, valueNode).operation, 'max');
      expect(AtomicFunctionNode.atomicMin(pointerNode, valueNode).operation, 'min');
      expect(AtomicFunctionNode.atomicAnd(pointerNode, valueNode).operation, 'and');
      expect(AtomicFunctionNode.atomicOr(pointerNode, valueNode).operation, 'or');
      expect(AtomicFunctionNode.atomicXor(pointerNode, valueNode).operation, 'xor');
      expect(AtomicFunctionNode.atomicExchange(pointerNode, valueNode).operation, 'exchange');
    });
    
    test('serializes to JSON', () {
      AtomicFunctionNode node = AtomicFunctionNode(
        'add',
        pointerNode: pointerNode,
        valueNode: valueNode
      );
      
      Map<String, dynamic> json = node.toJSON();
      
      expect(json['type'], 'AtomicFunctionNode');
      expect(json['operation'], 'add');
      expect(json['pointerNode'], isNotNull);
      expect(json['valueNode'], isNotNull);
    });
  });
  
  group('BarrierNode', () {
    test('creates workgroup barrier', () {
      BarrierNode node = BarrierNode('workgroup');
      
      expect(node.nodeType, 'BarrierNode');
      expect(node.barrierType, 'workgroup');
    });
    
    test('creates memory barrier', () {
      BarrierNode node = BarrierNode('memory');
      
      expect(node.barrierType, 'memory');
    });
    
    test('creates buffer barrier', () {
      BarrierNode node = BarrierNode('buffer');
      
      expect(node.barrierType, 'buffer');
    });
    
    test('creates image barrier', () {
      BarrierNode node = BarrierNode('image');
      
      expect(node.barrierType, 'image');
    });
    
    test('rejects invalid barrier type', () {
      expect(
        () => BarrierNode('invalid'),
        throwsArgumentError
      );
    });
    
    test('builds barrier in compute stage', () {
      BarrierNode node = BarrierNode('workgroup');
      NodeBuilder builder = NodeBuilder();
      builder.shaderStage = 'compute';
      
      String result = node.build(builder, 'void');
      
      // Verify the build completed without errors
      expect(result, isNotNull);
    });
    
    test('throws error when used outside compute stage', () {
      BarrierNode node = BarrierNode('workgroup');
      NodeBuilder builder = NodeBuilder();
      builder.shaderStage = 'fragment';
      
      expect(
        () => node.build(builder, 'void'),
        throwsStateError
      );
    });
    
    test('convenience factory methods work', () {
      expect(BarrierNode.workgroup().barrierType, 'workgroup');
      expect(BarrierNode.memory().barrierType, 'memory');
      expect(BarrierNode.buffer().barrierType, 'buffer');
      expect(BarrierNode.image().barrierType, 'image');
    });
    
    test('serializes to JSON', () {
      BarrierNode node = BarrierNode('workgroup');
      Map<String, dynamic> json = node.toJSON();
      
      expect(json['type'], 'BarrierNode');
      expect(json['barrierType'], 'workgroup');
    });
  });
  
  group('SubgroupFunctionNode', () {
    test('creates barrier operation', () {
      SubgroupFunctionNode node = SubgroupFunctionNode('barrier');
      
      expect(node.nodeType, 'SubgroupFunctionNode');
      expect(node.operation, 'barrier');
    });
    
    test('creates elect operation', () {
      SubgroupFunctionNode node = SubgroupFunctionNode('elect');
      
      expect(node.operation, 'elect');
    });
    
    test('creates all operation with value', () {
      Node valueNode = CodeNode('condition');
      SubgroupFunctionNode node = SubgroupFunctionNode(
        'all',
        valueNode: valueNode
      );
      
      expect(node.operation, 'all');
      expect(node.valueNode, isNotNull);
    });
    
    test('creates broadcast operation with value and id', () {
      Node valueNode = CodeNode('value');
      Node idNode = CodeNode('0');
      SubgroupFunctionNode node = SubgroupFunctionNode(
        'broadcast',
        valueNode: valueNode,
        idNode: idNode
      );
      
      expect(node.operation, 'broadcast');
      expect(node.valueNode, isNotNull);
      expect(node.idNode, isNotNull);
    });
    
    test('rejects invalid operation', () {
      expect(
        () => SubgroupFunctionNode('invalid'),
        throwsArgumentError
      );
    });
    
    test('requires valueNode for most operations', () {
      expect(
        () => SubgroupFunctionNode('all'),
        throwsArgumentError
      );
    });
    
    test('requires idNode for broadcast', () {
      Node valueNode = CodeNode('value');
      expect(
        () => SubgroupFunctionNode('broadcast', valueNode: valueNode),
        throwsArgumentError
      );
    });
    
    test('generates correct GLSL for barrier', () {
      SubgroupFunctionNode node = SubgroupFunctionNode('barrier');
      NodeBuilder builder = NodeBuilder();
      builder.shaderStage = 'compute';
      
      String glsl = node.generate(builder, 'void');
      
      expect(glsl, 'subgroupBarrier()');
    });
    
    test('generates correct GLSL for all operation', () {
      Node valueNode = CodeNode('condition');
      SubgroupFunctionNode node = SubgroupFunctionNode(
        'all',
        valueNode: valueNode
      );
      
      NodeBuilder builder = NodeBuilder();
      builder.shaderStage = 'compute';
      
      String glsl = node.generate(builder, 'bool');
      
      expect(glsl, contains('subgroupAll'));
    });
    
    test('throws error when used outside compute stage', () {
      SubgroupFunctionNode node = SubgroupFunctionNode('barrier');
      NodeBuilder builder = NodeBuilder();
      builder.shaderStage = 'fragment';
      
      expect(
        () => node.generate(builder, 'void'),
        throwsStateError
      );
    });
    
    test('convenience factory methods work', () {
      Node valueNode = CodeNode('value');
      Node idNode = CodeNode('0');
      
      expect(SubgroupFunctionNode.barrier().operation, 'barrier');
      expect(SubgroupFunctionNode.elect().operation, 'elect');
      expect(SubgroupFunctionNode.subgroupAll(valueNode).operation, 'all');
      expect(SubgroupFunctionNode.subgroupAny(valueNode).operation, 'any');
      expect(SubgroupFunctionNode.broadcast(valueNode, idNode).operation, 'broadcast');
      expect(SubgroupFunctionNode.subgroupAdd(valueNode).operation, 'add');
      expect(SubgroupFunctionNode.subgroupMul(valueNode).operation, 'mul');
      expect(SubgroupFunctionNode.subgroupMin(valueNode).operation, 'min');
      expect(SubgroupFunctionNode.subgroupMax(valueNode).operation, 'max');
    });
    
    test('serializes to JSON', () {
      Node valueNode = CodeNode('value');
      SubgroupFunctionNode node = SubgroupFunctionNode(
        'all',
        valueNode: valueNode
      );
      
      Map<String, dynamic> json = node.toJSON();
      
      expect(json['type'], 'SubgroupFunctionNode');
      expect(json['operation'], 'all');
      expect(json['valueNode'], isNotNull);
    });
  });
  
  group('WorkgroupInfoNode', () {
    test('creates size info node', () {
      WorkgroupInfoNode node = WorkgroupInfoNode('size');
      
      expect(node.nodeType, 'WorkgroupInfoNode');
      expect(node.infoType, 'size');
      expect(node.getInfoGLSLType(), 'uvec3');
    });
    
    test('creates subgroupSize info node', () {
      WorkgroupInfoNode node = WorkgroupInfoNode('subgroupSize');
      
      expect(node.infoType, 'subgroupSize');
      expect(node.getInfoGLSLType(), 'uint');
    });
    
    test('creates numSubgroups info node', () {
      WorkgroupInfoNode node = WorkgroupInfoNode('numSubgroups');
      
      expect(node.infoType, 'numSubgroups');
      expect(node.getInfoGLSLType(), 'uint');
    });
    
    test('creates subgroupID info node', () {
      WorkgroupInfoNode node = WorkgroupInfoNode('subgroupID');
      
      expect(node.infoType, 'subgroupID');
      expect(node.getInfoGLSLType(), 'uint');
    });
    
    test('rejects invalid info type', () {
      expect(
        () => WorkgroupInfoNode('invalid'),
        throwsArgumentError
      );
    });
    
    test('generates correct GLSL in compute stage', () {
      WorkgroupInfoNode node = WorkgroupInfoNode('size');
      NodeBuilder builder = NodeBuilder();
      builder.shaderStage = 'compute';
      
      String glsl = node.generate(builder, 'uvec3');
      
      expect(glsl, 'gl_WorkGroupSize');
    });
    
    test('throws error when used outside compute stage', () {
      WorkgroupInfoNode node = WorkgroupInfoNode('size');
      NodeBuilder builder = NodeBuilder();
      builder.shaderStage = 'fragment';
      
      expect(
        () => node.generate(builder, 'uvec3'),
        throwsStateError
      );
    });
    
    test('convenience factory methods work', () {
      expect(WorkgroupInfoNode.size().infoType, 'size');
      expect(WorkgroupInfoNode.subgroupSize().infoType, 'subgroupSize');
      expect(WorkgroupInfoNode.numSubgroups().infoType, 'numSubgroups');
      expect(WorkgroupInfoNode.subgroupID().infoType, 'subgroupID');
    });
    
    test('serializes to JSON', () {
      WorkgroupInfoNode node = WorkgroupInfoNode('size');
      Map<String, dynamic> json = node.toJSON();
      
      expect(json['type'], 'WorkgroupInfoNode');
      expect(json['infoType'], 'size');
    });
  });
}

