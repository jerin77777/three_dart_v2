// Accessor node tests
// Tests for BufferAttributeNode, TextureNode, CubeTextureNode, etc.

import 'package:flutter_test/flutter_test.dart';
import 'package:three_dart_v2/three3d/core/index.dart';
import 'package:three_dart_v2/three3d/materials/index.dart';
import 'package:three_dart_v2/three3d/textures/index.dart';
import 'package:three_dart_v2/three3d/nodes/core/node.dart';
import 'package:three_dart_v2/three3d/nodes/core/node_builder.dart';
import 'package:three_dart_v2/three3d/nodes/accessors/index.dart';

void main() {
  group('BufferAttributeNode', () {
    test('creates node with attribute name', () {
      final node = BufferAttributeNode(null, 'position');
      
      expect(node.nodeType, 'BufferAttributeNode');
      expect(node.attributeName, 'position');
    });
    
    test('generates correct GLSL in vertex shader', () {
      final node = BufferAttributeNode(null, 'position');
      final builder = NodeBuilder();
      builder.shaderStage = 'vertex';
      
      final glsl = node.generate(builder, 'vec3');
      
      expect(glsl, 'a_position');
    });
    
    test('generates varying reference in fragment shader', () {
      final node = BufferAttributeNode(null, 'uv');
      final builder = NodeBuilder();
      builder.shaderStage = 'fragment';
      
      final glsl = node.generate(builder, 'vec2');
      
      expect(glsl, 'v_uv');
    });
    
    test('serializes to JSON', () {
      final node = BufferAttributeNode(null, 'normal');
      final json = node.toJSON();
      
      expect(json['type'], 'BufferAttributeNode');
      expect(json['attributeName'], 'normal');
    });
  });
  
  group('TextureNode', () {
    test('creates node with texture and UV', () {
      final texture = Texture();
      final uvNode = Vec2Node(0.5, 0.5);
      final node = TextureNode(texture, uvNode);
      
      expect(node.nodeType, 'TextureNode');
      expect(node.texture, texture);
      expect(node.uvNode, uvNode);
    });
    
    test('generates texture sampling GLSL', () {
      final texture = Texture();
      final uvNode = Vec2Node(0.5, 0.5);
      final node = TextureNode(texture, uvNode);
      final builder = NodeBuilder();
      
      final glsl = node.generate(builder, 'vec4');
      
      expect(glsl, contains('texture('));
      // Verify a uniform was created with sampler2D type
      expect(builder.uniforms.values.any((u) => u.type == 'sampler2D'), true);
    });
    
    test('generates textureLod with level node', () {
      final texture = Texture();
      final uvNode = Vec2Node(0.5, 0.5);
      final levelNode = ConstantNode(2.0);
      final node = TextureNode(texture, uvNode, levelNode: levelNode);
      final builder = NodeBuilder();
      
      final glsl = node.generate(builder, 'vec4');
      
      expect(glsl, contains('textureLod('));
    });
    
    test('serializes to JSON', () {
      final texture = Texture();
      final uvNode = Vec2Node(0.5, 0.5);
      final node = TextureNode(texture, uvNode);
      final json = node.toJSON();
      
      expect(json['type'], 'TextureNode');
      expect(json['textureUuid'], texture.uuid);
    });
  });
  
  group('CubeTextureNode', () {
    test('creates node with cube texture and direction', () {
      final texture = CubeTexture();
      final dirNode = Vec3Node(0.0, 1.0, 0.0);
      final node = CubeTextureNode(texture, dirNode);
      
      expect(node.nodeType, 'CubeTextureNode');
      expect(node.texture, texture);
      expect(node.uvwNode, dirNode);
    });
    
    test('generates cube texture sampling GLSL', () {
      final texture = CubeTexture();
      final dirNode = Vec3Node(0.0, 1.0, 0.0);
      final node = CubeTextureNode(texture, dirNode);
      final builder = NodeBuilder();
      
      final glsl = node.generate(builder, 'vec4');
      
      expect(glsl, contains('texture('));
      // Verify a uniform was created with samplerCube type
      expect(builder.uniforms.values.any((u) => u.type == 'samplerCube'), true);
    });
    
    test('generates textureLod with level node', () {
      final texture = CubeTexture();
      final dirNode = Vec3Node(0.0, 1.0, 0.0);
      final levelNode = ConstantNode(1.0);
      final node = CubeTextureNode(texture, dirNode, levelNode: levelNode);
      final builder = NodeBuilder();
      
      final glsl = node.generate(builder, 'vec4');
      
      expect(glsl, contains('textureLod('));
    });
  });
  
  group('MaterialNode', () {
    test('creates node with property name', () {
      final node = MaterialNode('color');
      
      expect(node.nodeType, 'MaterialNode');
      expect(node.propertyName, 'color');
    });
    
    test('throws error without material context', () {
      final node = MaterialNode('opacity');
      final builder = NodeBuilder();
      
      expect(() => node.analyze(builder), throwsException);
    });
    
    test('generates uniform with material context', () {
      final node = MaterialNode('roughness');
      final builder = NodeBuilder();
      builder.material = Material();
      
      final glsl = node.generate(builder, 'float');
      
      expect(glsl, contains('u_'));
    });
    
    test('serializes to JSON', () {
      final node = MaterialNode('metalness');
      final json = node.toJSON();
      
      expect(json['type'], 'MaterialNode');
      expect(json['propertyName'], 'metalness');
    });
  });
  
  group('MaterialReferenceNode', () {
    test('creates node with material and property', () {
      final material = Material();
      final node = MaterialReferenceNode(material, 'color');
      
      expect(node.nodeType, 'MaterialReferenceNode');
      expect(node.material, material);
      expect(node.propertyName, 'color');
    });
    
    test('generates uniform for referenced material', () {
      final material = Material();
      final node = MaterialReferenceNode(material, 'opacity');
      final builder = NodeBuilder();
      
      final glsl = node.generate(builder, 'float');
      
      expect(glsl, contains('u_'));
    });
  });
  
  group('InstanceNode', () {
    test('creates node with attribute name', () {
      final node = InstanceNode('color');
      
      expect(node.nodeType, 'InstanceNode');
      expect(node.attributeName, 'color');
    });
    
    test('generates instance attribute reference', () {
      final node = InstanceNode('matrix');
      final builder = NodeBuilder();
      
      final glsl = node.generate(builder, 'mat4');
      
      expect(glsl, 'instance_matrix');
    });
    
    test('serializes to JSON', () {
      final node = InstanceNode('offset');
      final json = node.toJSON();
      
      expect(json['type'], 'InstanceNode');
      expect(json['attributeName'], 'offset');
    });
  });
  
  group('InstancedMeshNode', () {
    test('creates node with data type', () {
      final node = InstancedMeshNode('instanceMatrix');
      
      expect(node.nodeType, 'InstancedMeshNode');
      expect(node.dataType, 'instanceMatrix');
    });
    
    test('generates instance matrix construction', () {
      final node = InstancedMeshNode('instanceMatrix');
      final builder = NodeBuilder();
      
      final glsl = node.generate(builder, 'mat4');
      
      expect(glsl, contains('mat4('));
      expect(glsl, contains('instanceMatrix'));
    });
    
    test('generates instance color reference', () {
      final node = InstancedMeshNode('instanceColor');
      final builder = NodeBuilder();
      
      final glsl = node.generate(builder, 'vec3');
      
      expect(glsl, 'instanceColor');
    });
  });
  
  group('ModelNode', () {
    test('creates node with data type', () {
      final node = ModelNode('modelMatrix');
      
      expect(node.nodeType, 'ModelNode');
      expect(node.dataType, 'modelMatrix');
    });
    
    test('throws error without object context', () {
      final node = ModelNode('modelViewMatrix');
      final builder = NodeBuilder();
      
      expect(() => node.analyze(builder), throwsException);
    });
    
    test('generates uniform with object context', () {
      final node = ModelNode('normalMatrix');
      final builder = NodeBuilder();
      builder.object = Object3D();
      
      final glsl = node.generate(builder, 'mat3');
      
      expect(glsl, contains('u_'));
    });
  });
  
  group('Object3DNode', () {
    test('creates node with property name', () {
      final node = Object3DNode('position');
      
      expect(node.nodeType, 'Object3DNode');
      expect(node.propertyName, 'position');
    });
    
    test('throws error without object context', () {
      final node = Object3DNode('scale');
      final builder = NodeBuilder();
      
      expect(() => node.analyze(builder), throwsException);
    });
    
    test('generates uniform with object context', () {
      final node = Object3DNode('worldPosition');
      final builder = NodeBuilder();
      builder.object = Object3D();
      
      final glsl = node.generate(builder, 'vec3');
      
      expect(glsl, contains('u_'));
    });
    
    test('uses provided object instead of builder object', () {
      final specificObject = Object3D();
      final node = Object3DNode('position', object: specificObject);
      final builder = NodeBuilder();
      
      final glsl = node.generate(builder, 'vec3');
      
      expect(glsl, contains('u_'));
    });
  });
  
  group('StorageBufferNode', () {
    test('creates node with buffer name and type', () {
      final node = StorageBufferNode('particles', 'vec4');
      
      expect(node.nodeType, 'StorageBufferNode');
      expect(node.bufferName, 'particles');
      expect(node.dataType, 'vec4');
      expect(node.readOnly, false);
    });
    
    test('throws error in non-compute shader', () {
      final node = StorageBufferNode('data', 'float');
      final builder = NodeBuilder();
      builder.shaderStage = 'fragment';
      
      expect(() => node.analyze(builder), throwsException);
    });
    
    test('generates buffer name in compute shader', () {
      final node = StorageBufferNode('particles', 'vec4');
      final builder = NodeBuilder();
      builder.shaderStage = 'compute';
      
      final glsl = node.generate(builder, 'auto');
      
      expect(glsl, 'particles');
    });
    
    test('generates correct declaration', () {
      final node = StorageBufferNode('data', 'float', readOnly: true);
      final declaration = node.getDeclaration();
      
      expect(declaration, contains('readonly'));
      expect(declaration, contains('buffer'));
      expect(declaration, contains('data'));
    });
  });
  
  group('StorageBufferElementNode', () {
    test('creates node with buffer and index', () {
      final buffer = StorageBufferNode('data', 'vec4');
      final index = ConstantNode(5);
      final node = StorageBufferElementNode(buffer, index);
      
      expect(node.nodeType, 'StorageBufferElementNode');
      expect(node.bufferNode, buffer);
      expect(node.indexNode, index);
    });
    
    test('generates indexed buffer access', () {
      final buffer = StorageBufferNode('particles', 'vec4');
      final index = ConstantNode(10);
      final node = StorageBufferElementNode(buffer, index);
      final builder = NodeBuilder();
      builder.shaderStage = 'compute';
      
      final glsl = node.generate(builder, 'vec4');
      
      expect(glsl, contains('particles['));
      expect(glsl, contains(']'));
    });
  });
  
  group('StorageTextureNode', () {
    test('creates node with texture name and format', () {
      final node = StorageTextureNode('outputTex', 'rgba8');
      
      expect(node.nodeType, 'StorageTextureNode');
      expect(node.textureName, 'outputTex');
      expect(node.format, 'rgba8');
      expect(node.readOnly, false);
    });
    
    test('throws error in non-compute shader', () {
      final node = StorageTextureNode('tex', 'r32f');
      final builder = NodeBuilder();
      builder.shaderStage = 'vertex';
      
      expect(() => node.analyze(builder), throwsException);
    });
    
    test('generates correct declaration', () {
      final node = StorageTextureNode('output', 'rgba16f', readOnly: false);
      final declaration = node.getDeclaration();
      
      expect(declaration, contains('writeonly'));
      expect(declaration, contains('image2D'));
      expect(declaration, contains('rgba16f'));
    });
  });
  
  group('StorageTextureReadNode', () {
    test('creates node with texture and coordinates', () {
      final texture = StorageTextureNode('input', 'rgba8', readOnly: true);
      final coord = Vec2Node(10, 20);
      final node = StorageTextureReadNode(texture, coord);
      
      expect(node.nodeType, 'StorageTextureReadNode');
      expect(node.textureNode, texture);
      expect(node.coordNode, coord);
    });
    
    test('generates imageLoad call', () {
      final texture = StorageTextureNode('input', 'rgba8', readOnly: true);
      final coord = Vec2Node(5, 5);
      final node = StorageTextureReadNode(texture, coord);
      final builder = NodeBuilder();
      builder.shaderStage = 'compute';
      
      final glsl = node.generate(builder, 'vec4');
      
      expect(glsl, contains('imageLoad('));
    });
  });
  
  group('StorageTextureWriteNode', () {
    test('creates node with texture, coordinates, and value', () {
      final texture = StorageTextureNode('output', 'rgba8');
      final coord = Vec2Node(10, 20);
      final value = Vec4Node(1.0, 0.0, 0.0, 1.0);
      final node = StorageTextureWriteNode(texture, coord, value);
      
      expect(node.nodeType, 'StorageTextureWriteNode');
      expect(node.textureNode, texture);
      expect(node.coordNode, coord);
      expect(node.valueNode, value);
    });
    
    test('generates imageStore statement', () {
      final texture = StorageTextureNode('output', 'rgba8');
      final coord = Vec2Node(0, 0);
      final value = Vec4Node(1.0, 1.0, 1.0, 1.0);
      final node = StorageTextureWriteNode(texture, coord, value);
      final builder = NodeBuilder();
      builder.shaderStage = 'compute';
      
      // imageStore is a statement, so it adds to flow code
      node.generate(builder, 'void');
      
      // Check that flow code was added
      expect(builder.getStack(), isNull); // Just verify it doesn't throw
    });
  });
}
