import 'package:flutter_test/flutter_test.dart';
import 'package:three_dart_v2/three3d/nodes/core/index.dart';

void main() {
  group('Node Base Class', () {
    test('Node generates unique UUIDs', () {
      final node1 = TestNode();
      final node2 = TestNode();
      final node3 = TestNode();
      
      expect(node1.uuid, isNotEmpty);
      expect(node2.uuid, isNotEmpty);
      expect(node3.uuid, isNotEmpty);
      
      // All UUIDs should be unique
      expect(node1.uuid, isNot(equals(node2.uuid)));
      expect(node1.uuid, isNot(equals(node3.uuid)));
      expect(node2.uuid, isNot(equals(node3.uuid)));
    });
    
    test('Node type conversion methods work', () {
      final node = TestNode();
      
      expect(node.toFloat(), isA<ConvertNode>());
      expect(node.toInt(), isA<ConvertNode>());
      expect(node.toVec2(), isA<ConvertNode>());
      expect(node.toVec3(), isA<ConvertNode>());
      expect(node.toVec4(), isA<ConvertNode>());
    });
    
    test('Node operator methods create OperatorNodes', () {
      final node1 = TestNode();
      final node2 = TestNode();
      
      expect(node1.add(node2), isA<OperatorNode>());
      expect(node1.sub(node2), isA<OperatorNode>());
      expect(node1.mul(node2), isA<OperatorNode>());
      expect(node1.div(node2), isA<OperatorNode>());
    });
    
    test('Node can be serialized to JSON', () {
      final node = TestNode();
      node.nodeType = 'TestNode';
      node.userData = {'test': 'value'};
      
      final json = node.toJSON();
      
      expect(json['uuid'], equals(node.uuid));
      expect(json['type'], equals('TestNode'));
      expect(json['userData'], equals({'test': 'value'}));
    });
    
    test('ConstantNode generates correct GLSL', () {
      final builder = NodeBuilder();
      
      final node1 = ConstantNode(1.0);
      expect(node1.generate(builder, 'float'), equals('1.0'));
      
      final node2 = ConstantNode(3.14159);
      expect(node2.generate(builder, 'float'), equals('3.14159'));
    });
    
    test('Vec2Node generates correct GLSL', () {
      final builder = NodeBuilder();
      final node = Vec2Node(1.0, 2.0);
      
      expect(node.generate(builder, 'vec2'), equals('vec2(1.0, 2.0)'));
    });
    
    test('Vec3Node generates correct GLSL', () {
      final builder = NodeBuilder();
      final node = Vec3Node(1.0, 2.0, 3.0);
      
      expect(node.generate(builder, 'vec3'), equals('vec3(1.0, 2.0, 3.0)'));
    });
    
    test('Vec4Node generates correct GLSL', () {
      final builder = NodeBuilder();
      final node = Vec4Node(1.0, 2.0, 3.0, 4.0);
      
      expect(node.generate(builder, 'vec4'), equals('vec4(1.0, 2.0, 3.0, 4.0)'));
    });
    
    test('OperatorNode generates correct GLSL', () {
      final builder = NodeBuilder();
      final a = ConstantNode(1.0);
      final b = ConstantNode(2.0);
      
      final add = OperatorNode('+', a, b);
      expect(add.generate(builder, 'float'), equals('(1.0 + 2.0)'));
      
      final mul = OperatorNode('*', a, b);
      expect(mul.generate(builder, 'float'), equals('(1.0 * 2.0)'));
    });
    
    test('MathNode generates correct GLSL', () {
      final builder = NodeBuilder();
      final a = ConstantNode(1.0);
      final b = ConstantNode(2.0);
      
      final sin = MathNode('sin', a);
      expect(sin.generate(builder, 'float'), equals('sin(1.0)'));
      
      final pow = MathNode('pow', a, b);
      expect(pow.generate(builder, 'float'), equals('pow(1.0, 2.0)'));
    });
  });
  
  group('NodeBuilder', () {
    test('NodeBuilder initializes correctly', () {
      final builder = NodeBuilder();
      
      expect(builder.shaderStage, equals('fragment'));
      expect(builder.nodes, isEmpty);
      expect(builder.uniforms, isEmpty);
      expect(builder.attributes, isEmpty);
      expect(builder.varyings, isEmpty);
    });
    
    test('NodeBuilder generates unique variable names', () {
      final builder = NodeBuilder();
      
      final name1 = builder.getUniqueVarName();
      final name2 = builder.getUniqueVarName();
      final name3 = builder.getUniqueVarName();
      
      expect(name1, isNot(equals(name2)));
      expect(name1, isNot(equals(name3)));
      expect(name2, isNot(equals(name3)));
    });
    
    test('NodeBuilder creates uniforms', () {
      final builder = NodeBuilder();
      final node = TestNode();
      
      final uniformName = builder.getUniformFromNode(node, 'float');
      
      expect(uniformName, startsWith('u_'));
      expect(builder.uniforms, isNotEmpty);
      expect(builder.uniforms[uniformName], isNotNull);
      expect(builder.uniforms[uniformName]!.type, equals('float'));
    });
    
    test('NodeBuilder creates attributes', () {
      final builder = NodeBuilder();
      final node = TestNode();
      
      final attrName = builder.getAttributeFromNode(node, 'vec3');
      
      expect(attrName, startsWith('a_'));
      expect(builder.attributes, isNotEmpty);
      expect(builder.attributes[attrName], isNotNull);
      expect(builder.attributes[attrName]!.type, equals('vec3'));
    });
    
    test('NodeBuilder creates varyings', () {
      final builder = NodeBuilder();
      final node = TestNode();
      
      final varyingName = builder.getVaryingFromNode(node, 'vec2');
      
      expect(varyingName, startsWith('v_'));
      expect(builder.varyings, isNotEmpty);
      expect(builder.varyings[varyingName], isNotNull);
      expect(builder.varyings[varyingName]!.type, equals('vec2'));
    });
    
    test('NodeBuilder generates GLSL version directive', () {
      final builder = NodeBuilder();
      
      expect(builder.getVersionDirective(), contains('#version'));
    });
    
    test('NodeBuilder generates precision qualifiers', () {
      final builder = NodeBuilder();
      
      final precision = builder.getPrecisionQualifiers();
      expect(precision, contains('precision'));
      expect(precision, contains('float'));
    });
  });
  
  group('NodeFrame', () {
    test('NodeFrame initializes correctly', () {
      final frame = NodeFrame();
      
      expect(frame.frameId, equals(0));
      expect(frame.renderId, equals(0));
      expect(frame.time, equals(0.0));
      expect(frame.deltaTime, equals(0.0));
    });
    
    test('NodeFrame updates frame ID', () {
      final frame = NodeFrame();
      
      frame.update();
      expect(frame.frameId, equals(1));
      
      frame.update();
      expect(frame.frameId, equals(2));
    });
    
    test('NodeFrame updates render ID', () {
      final frame = NodeFrame();
      
      frame.updateForRender();
      expect(frame.renderId, equals(1));
      
      frame.updateForRender();
      expect(frame.renderId, equals(2));
    });
    
    test('NodeFrame stores and retrieves frame data', () {
      final frame = NodeFrame();
      
      frame.setFrameData('test', 'value');
      expect(frame.getFrameData('test'), equals('value'));
      expect(frame.hasFrameData('test'), isTrue);
      
      frame.removeFrameData('test');
      expect(frame.hasFrameData('test'), isFalse);
    });
    
    test('NodeFrame can be reset', () {
      final frame = NodeFrame();
      
      frame.update();
      frame.updateForRender();
      frame.setFrameData('test', 'value');
      
      frame.reset();
      
      expect(frame.frameId, equals(0));
      expect(frame.renderId, equals(0));
      expect(frame.hasFrameData('test'), isFalse);
    });
  });
  
  group('NodeCache', () {
    test('NodeCache stores and retrieves values', () {
      final cache = NodeCache();
      
      cache.set('key1', 'value1');
      expect(cache.get('key1'), equals('value1'));
      expect(cache.has('key1'), isTrue);
    });
    
    test('NodeCache deletes values', () {
      final cache = NodeCache();
      
      cache.set('key1', 'value1');
      cache.delete('key1');
      
      expect(cache.has('key1'), isFalse);
      expect(cache.get('key1'), isNull);
    });
    
    test('NodeCache clears all values', () {
      final cache = NodeCache();
      
      cache.set('key1', 'value1');
      cache.set('key2', 'value2');
      cache.setProgram('prog1', 'program');
      
      cache.clear();
      
      expect(cache.has('key1'), isFalse);
      expect(cache.has('key2'), isFalse);
      expect(cache.hasProgram('prog1'), isFalse);
    });
    
    test('NodeCache manages shader programs', () {
      final cache = NodeCache();
      
      cache.setProgram('shader1', 'program1');
      expect(cache.getProgram('shader1'), equals('program1'));
      expect(cache.hasProgram('shader1'), isTrue);
      expect(cache.programCount, equals(1));
    });
    
    test('NodeCache manages uniform locations', () {
      final cache = NodeCache();
      
      cache.setUniformLocation('uniform1', 'location1');
      expect(cache.getUniformLocation('uniform1'), equals('location1'));
      expect(cache.hasUniformLocation('uniform1'), isTrue);
      expect(cache.uniformLocationCount, equals(1));
    });
    
    test('NodeCache provides statistics', () {
      final cache = NodeCache();
      
      cache.set('key1', 'value1');
      cache.setProgram('prog1', 'program');
      cache.setUniformLocation('uniform1', 'location');
      
      final stats = cache.getStatistics();
      
      expect(stats['general'], equals(1));
      expect(stats['programs'], equals(1));
      expect(stats['uniformLocations'], equals(1));
      expect(stats['total'], equals(3));
    });
  });
  
  group('NodeUniform', () {
    test('NodeUniform initializes correctly', () {
      final node = TestNode();
      final uniform = NodeUniform(
        name: 'u_test',
        type: 'float',
        node: node,
      );
      
      expect(uniform.name, equals('u_test'));
      expect(uniform.type, equals('float'));
      expect(uniform.needsUpdate, isTrue);
    });
    
    test('NodeUniform can be marked for update', () {
      final node = TestNode();
      final uniform = NodeUniform(
        name: 'u_test',
        type: 'float',
        node: node,
      );
      
      uniform.needsUpdate = false;
      expect(uniform.needsUpdate, isFalse);
      
      uniform.markNeedsUpdate();
      expect(uniform.needsUpdate, isTrue);
    });
  });
  
  group('NodeAttribute', () {
    test('NodeAttribute initializes correctly', () {
      final attribute = NodeAttribute(
        name: 'a_position',
        type: 'vec3',
      );
      
      expect(attribute.name, equals('a_position'));
      expect(attribute.type, equals('vec3'));
      expect(attribute.enabled, isTrue);
    });
    
    test('NodeAttribute can be enabled/disabled', () {
      final attribute = NodeAttribute(
        name: 'a_position',
        type: 'vec3',
      );
      
      attribute.disable();
      expect(attribute.enabled, isFalse);
      
      attribute.enable();
      expect(attribute.enabled, isTrue);
    });
  });
  
  group('NodeVarying', () {
    test('NodeVarying initializes correctly', () {
      final node = TestNode();
      final varying = NodeVarying(
        name: 'v_uv',
        type: 'vec2',
        node: node,
      );
      
      expect(varying.name, equals('v_uv'));
      expect(varying.type, equals('vec2'));
      expect(varying.interpolation, equals('smooth'));
    });
    
    test('NodeVarying generates vertex declaration', () {
      final node = TestNode();
      final varying = NodeVarying(
        name: 'v_uv',
        type: 'vec2',
        node: node,
      );
      
      final decl = varying.getVertexDeclaration();
      expect(decl, contains('out'));
      expect(decl, contains('vec2'));
      expect(decl, contains('v_uv'));
    });
    
    test('NodeVarying generates fragment declaration', () {
      final node = TestNode();
      final varying = NodeVarying(
        name: 'v_uv',
        type: 'vec2',
        node: node,
      );
      
      final decl = varying.getFragmentDeclaration();
      expect(decl, contains('in'));
      expect(decl, contains('vec2'));
      expect(decl, contains('v_uv'));
    });
    
    test('NodeVarying supports interpolation modes', () {
      final node = TestNode();
      final varying = NodeVarying(
        name: 'v_uv',
        type: 'vec2',
        node: node,
      );
      
      varying.setInterpolation('flat');
      expect(varying.interpolation, equals('flat'));
      
      final decl = varying.getVertexDeclaration();
      expect(decl, contains('flat'));
    });
  });
}

// Test helper class
class TestNode extends Node {
  @override
  String generate(NodeBuilder builder, String output) {
    return 'test_value';
  }
}
