// Function node tests
// Tests for CodeNode, ExpressionNode, FunctionNode, FunctionCallNode, etc.

import 'package:flutter_test/flutter_test.dart';
import 'package:three_dart_v2/three3d/nodes/core/node.dart';
import 'package:three_dart_v2/three3d/nodes/core/node_builder.dart';
import 'package:three_dart_v2/three3d/nodes/core/validation_error.dart';
import 'package:three_dart_v2/three3d/nodes/functions/index.dart';

void main() {
  group('CodeNode', () {
    late NodeBuilder builder;

    setUp(() {
      builder = NodeBuilder();
    });

    test('creates CodeNode with raw code', () {
      var codeNode = CodeNode('vec3 result = vec3(1.0, 0.0, 0.0);');

      expect(codeNode.nodeType, equals('CodeNode'));
      expect(codeNode.code, equals('vec3 result = vec3(1.0, 0.0, 0.0);'));
    });

    test('generates raw GLSL code without placeholders', () {
      var codeNode = CodeNode('vec3 result = vec3(1.0, 0.0, 0.0);');

      var glsl = codeNode.generate(builder, 'vec3');
      expect(glsl, equals('vec3 result = vec3(1.0, 0.0, 0.0);'));
    });

    test('replaces placeholders with node values', () {
      var colorA = Vec3Node(1.0, 0.0, 0.0);
      var colorB = Vec3Node(0.0, 1.0, 0.0);
      var factor = ConstantNode(0.5);

      var codeNode = CodeNode(
        'vec3 result = mix(\${colorA}, \${colorB}, \${factor});',
        includes: {
          'colorA': colorA,
          'colorB': colorB,
          'factor': factor,
        },
      );

      var glsl = codeNode.generate(builder, 'vec3');
      expect(glsl, contains('mix'));
      expect(glsl, contains('vec3(1.0, 0.0, 0.0)'));
      expect(glsl, contains('vec3(0.0, 1.0, 0.0)'));
      expect(glsl, contains('0.5'));
    });

    test('handles multiple occurrences of same placeholder', () {
      var value = ConstantNode(2.0);

      var codeNode = CodeNode(
        'float result = \${value} * \${value};',
        includes: {'value': value},
      );

      var glsl = codeNode.generate(builder, 'float');
      expect(glsl, equals('float result = 2.0 * 2.0;'));
    });

    test('builds included nodes during analysis', () {
      var colorA = Vec3Node(1.0, 0.0, 0.0);
      var colorB = Vec3Node(0.0, 1.0, 0.0);

      var codeNode = CodeNode(
        'vec3 result = \${colorA} + \${colorB};',
        includes: {
          'colorA': colorA,
          'colorB': colorB,
        },
      );

      codeNode.analyze(builder);
      // If no exception is thrown, analysis succeeded
      expect(true, isTrue);
    });

    test('serializes to JSON correctly', () {
      var colorA = Vec3Node(1.0, 0.0, 0.0);
      var codeNode = CodeNode(
        'vec3 result = \${colorA};',
        includes: {'colorA': colorA},
      );

      var json = codeNode.toJSON();
      expect(json['type'], equals('CodeNode'));
      expect(json['code'], equals('vec3 result = \${colorA};'));
      expect(json['includes'], isNotNull);
      expect(json['includes']['colorA'], isNotNull);
    });

    test('works without includes', () {
      var codeNode = CodeNode('return vec3(1.0);');

      var glsl = codeNode.generate(builder, 'vec3');
      expect(glsl, equals('return vec3(1.0);'));
    });
  });

  group('ExpressionNode', () {
    late NodeBuilder builder;

    setUp(() {
      builder = NodeBuilder();
    });

    test('creates ExpressionNode with expression', () {
      var exprNode = ExpressionNode('1.0 + 2.0');

      expect(exprNode.nodeType, equals('ExpressionNode'));
      expect(exprNode.expression, equals('1.0 + 2.0'));
    });

    test('generates GLSL wrapped in parentheses', () {
      var exprNode = ExpressionNode('1.0 + 2.0');

      var glsl = exprNode.generate(builder, 'float');
      expect(glsl, equals('(1.0 + 2.0)'));
    });

    test('replaces placeholders with node values', () {
      var edge0 = ConstantNode(0.0);
      var edge1 = ConstantNode(1.0);
      var x = ConstantNode(0.5);

      var exprNode = ExpressionNode(
        'smoothstep(\${edge0}, \${edge1}, \${x})',
        includes: {
          'edge0': edge0,
          'edge1': edge1,
          'x': x,
        },
      );

      var glsl = exprNode.generate(builder, 'float');
      expect(glsl, equals('(smoothstep(0.0, 1.0, 0.5))'));
    });

    test('supports explicit return type', () {
      var value = ConstantNode(1.0);

      var exprNode = ExpressionNode(
        'vec3(\${value})',
        includes: {'value': value},
        returnType: 'vec3',
      );

      expect(exprNode.returnType, equals('vec3'));
    });

    test('builds included nodes during analysis', () {
      var a = ConstantNode(1.0);
      var b = ConstantNode(2.0);

      var exprNode = ExpressionNode(
        '\${a} + \${b}',
        includes: {'a': a, 'b': b},
      );

      exprNode.analyze(builder);
      expect(true, isTrue);
    });

    test('serializes to JSON correctly', () {
      var value = ConstantNode(1.0);
      var exprNode = ExpressionNode(
        '\${value} * 2.0',
        includes: {'value': value},
        returnType: 'float',
      );

      var json = exprNode.toJSON();
      expect(json['type'], equals('ExpressionNode'));
      expect(json['expression'], equals('\${value} * 2.0'));
      expect(json['returnType'], equals('float'));
      expect(json['includes'], isNotNull);
    });

    test('works without includes', () {
      var exprNode = ExpressionNode('1.0 + 2.0');

      var glsl = exprNode.generate(builder, 'float');
      expect(glsl, equals('(1.0 + 2.0)'));
    });
  });

  group('FunctionNode', () {
    late NodeBuilder builder;

    setUp(() {
      builder = NodeBuilder();
    });

    test('creates FunctionNode with parameters', () {
      var bodyNode = CodeNode('return a + b;');
      var funcNode = FunctionNode(
        name: 'add',
        parameters: [
          FunctionParameter(name: 'a', type: 'float'),
          FunctionParameter(name: 'b', type: 'float'),
        ],
        returnType: 'float',
        bodyNode: bodyNode,
      );

      expect(funcNode.nodeType, equals('FunctionNode'));
      expect(funcNode.name, equals('add'));
      expect(funcNode.parameters.length, equals(2));
      expect(funcNode.returnType, equals('float'));
    });

    test('declares function in shader', () {
      var bodyNode = CodeNode('return a + b;');
      var funcNode = FunctionNode(
        name: 'add',
        parameters: [
          FunctionParameter(name: 'a', type: 'float'),
          FunctionParameter(name: 'b', type: 'float'),
        ],
        returnType: 'float',
        bodyNode: bodyNode,
      );

      // Build the function node
      funcNode.build(builder, 'float');
      
      // Generate the shader
      var shader = builder.generate();

      // Check that function was added to builder
      expect(shader, contains('float add(float a, float b)'));
    });

    test('wraps simple expression in return statement', () {
      var bodyNode = ConstantNode(42.0);
      var funcNode = FunctionNode(
        name: 'getAnswer',
        parameters: [],
        returnType: 'float',
        bodyNode: bodyNode,
      );

      funcNode.build(builder, 'float');

      var shader = builder.generate();
      expect(shader, contains('return 42.0;'));
    });

    test('handles multi-line body code', () {
      var bodyNode = CodeNode('''
float result = a * b;
return result;
''');
      var funcNode = FunctionNode(
        name: 'multiply',
        parameters: [
          FunctionParameter(name: 'a', type: 'float'),
          FunctionParameter(name: 'b', type: 'float'),
        ],
        returnType: 'float',
        bodyNode: bodyNode,
      );

      funcNode.build(builder, 'float');

      var shader = builder.generate();
      expect(shader, contains('float multiply(float a, float b)'));
      expect(shader, contains('float result = a * b;'));
    });

    test('supports optional parameters', () {
      var bodyNode = CodeNode('return value;');
      var funcNode = FunctionNode(
        name: 'getValue',
        parameters: [
          FunctionParameter(name: 'value', type: 'float', required: false, defaultValue: 1.0),
        ],
        returnType: 'float',
        bodyNode: bodyNode,
      );

      expect(funcNode.parameters[0].required, isFalse);
      expect(funcNode.parameters[0].defaultValue, equals(1.0));
    });

    test('only declares function once', () {
      var bodyNode = CodeNode('return 1.0;');
      var funcNode = FunctionNode(
        name: 'getOne',
        parameters: [],
        returnType: 'float',
        bodyNode: bodyNode,
      );

      // Generate multiple times
      funcNode.build(builder, 'float');
      funcNode.build(builder, 'float');
      funcNode.build(builder, 'float');

      var shader = builder.generate();
      
      // Count occurrences of function declaration
      var count = 'float getOne()'.allMatches(shader).length;
      expect(count, equals(1));
    });

    test('resets declaration state on reset', () {
      var bodyNode = CodeNode('return 1.0;');
      var funcNode = FunctionNode(
        name: 'getOne',
        parameters: [],
        returnType: 'float',
        bodyNode: bodyNode,
      );

      funcNode.generate(builder, 'float');
      funcNode.reset();

      // After reset, should be able to declare again
      expect(funcNode.generate(builder, 'float'), equals('getOne'));
    });

    test('serializes to JSON correctly', () {
      var bodyNode = CodeNode('return a + b;');
      var funcNode = FunctionNode(
        name: 'add',
        parameters: [
          FunctionParameter(name: 'a', type: 'float'),
          FunctionParameter(name: 'b', type: 'float'),
        ],
        returnType: 'float',
        bodyNode: bodyNode,
      );

      var json = funcNode.toJSON();
      expect(json['type'], equals('FunctionNode'));
      expect(json['name'], equals('add'));
      expect(json['returnType'], equals('float'));
      expect(json['parameters'], isA<List>());
      expect(json['parameters'].length, equals(2));
      expect(json['bodyNode'], isNotNull);
    });
  });

  group('FunctionCallNode', () {
    late NodeBuilder builder;
    late FunctionNode testFunction;

    setUp(() {
      builder = NodeBuilder();
      testFunction = FunctionNode(
        name: 'add',
        parameters: [
          FunctionParameter(name: 'a', type: 'float'),
          FunctionParameter(name: 'b', type: 'float'),
        ],
        returnType: 'float',
        bodyNode: CodeNode('return a + b;'),
      );
    });

    test('creates FunctionCallNode', () {
      var arg1 = ConstantNode(1.0);
      var arg2 = ConstantNode(2.0);

      var callNode = FunctionCallNode(
        functionNode: testFunction,
        arguments: [arg1, arg2],
      );

      expect(callNode.nodeType, equals('FunctionCallNode'));
      expect(callNode.arguments.length, equals(2));
    });

    test('generates correct function call GLSL', () {
      var arg1 = ConstantNode(1.0);
      var arg2 = ConstantNode(2.0);

      var callNode = FunctionCallNode(
        functionNode: testFunction,
        arguments: [arg1, arg2],
      );

      var glsl = callNode.generate(builder, 'float');
      expect(glsl, equals('add(1.0, 2.0)'));
    });

    test('ensures function is declared before call', () {
      var arg1 = ConstantNode(1.0);
      var arg2 = ConstantNode(2.0);

      var callNode = FunctionCallNode(
        functionNode: testFunction,
        arguments: [arg1, arg2],
      );

      callNode.build(builder, 'float');

      var shader = builder.generate();
      expect(shader, contains('float add(float a, float b)'));
    });

    test('validates parameter count - too few', () {
      var arg1 = ConstantNode(1.0);

      var callNode = FunctionCallNode(
        functionNode: testFunction,
        arguments: [arg1], // Missing one argument
      );

      expect(
        () => callNode.analyze(builder),
        throwsA(isA<ValidationError>()),
      );
    });

    test('validates parameter count - too many', () {
      var arg1 = ConstantNode(1.0);
      var arg2 = ConstantNode(2.0);
      var arg3 = ConstantNode(3.0);

      var callNode = FunctionCallNode(
        functionNode: testFunction,
        arguments: [arg1, arg2, arg3], // Extra argument
      );

      expect(
        () => callNode.analyze(builder),
        throwsA(isA<ValidationError>()),
      );
    });

    test('validates parameter types', () {
      var funcWithVec3 = FunctionNode(
        name: 'processVector',
        parameters: [
          FunctionParameter(name: 'v', type: 'vec3'),
        ],
        returnType: 'vec3',
        bodyNode: CodeNode('return v;'),
      );

      var wrongArg = ConstantNode(1.0); // float instead of vec3

      var callNode = FunctionCallNode(
        functionNode: funcWithVec3,
        arguments: [wrongArg],
      );

      expect(
        () => callNode.analyze(builder),
        throwsA(isA<ValidationError>()),
      );
    });

    test('allows compatible type conversions', () {
      var arg1 = ConstantNode(1.0); // float
      var arg2 = ConstantNode(2.0); // float

      var callNode = FunctionCallNode(
        functionNode: testFunction,
        arguments: [arg1, arg2],
      );

      // Should not throw
      callNode.analyze(builder);
      expect(true, isTrue);
    });

    test('handles optional parameters', () {
      var funcWithOptional = FunctionNode(
        name: 'getValue',
        parameters: [
          FunctionParameter(name: 'value', type: 'float', required: false),
        ],
        returnType: 'float',
        bodyNode: CodeNode('return value;'),
      );

      // Call without optional parameter
      var callNode = FunctionCallNode(
        functionNode: funcWithOptional,
        arguments: [],
      );

      // Should not throw
      callNode.analyze(builder);
      expect(true, isTrue);
    });

    test('builds all argument nodes during analysis', () {
      var arg1 = ConstantNode(1.0);
      var arg2 = ConstantNode(2.0);

      var callNode = FunctionCallNode(
        functionNode: testFunction,
        arguments: [arg1, arg2],
      );

      callNode.analyze(builder);
      expect(true, isTrue);
    });

    test('serializes to JSON correctly', () {
      var arg1 = ConstantNode(1.0);
      var arg2 = ConstantNode(2.0);

      var callNode = FunctionCallNode(
        functionNode: testFunction,
        arguments: [arg1, arg2],
      );

      var json = callNode.toJSON();
      expect(json['type'], equals('FunctionCallNode'));
      expect(json['functionNode'], isNotNull);
      expect(json['arguments'], isA<List>());
      expect(json['arguments'].length, equals(2));
    });

    test('handles nested function calls', () {
      var innerCall = FunctionCallNode(
        functionNode: testFunction,
        arguments: [ConstantNode(1.0), ConstantNode(2.0)],
      );

      var outerCall = FunctionCallNode(
        functionNode: testFunction,
        arguments: [innerCall, ConstantNode(3.0)],
      );

      var glsl = outerCall.generate(builder, 'float');
      expect(glsl, contains('add(add(1.0, 2.0), 3.0)'));
    });
  });

  group('FunctionParameter', () {
    test('creates required parameter', () {
      var param = FunctionParameter(name: 'value', type: 'float');

      expect(param.name, equals('value'));
      expect(param.type, equals('float'));
      expect(param.required, isTrue);
      expect(param.defaultValue, isNull);
    });

    test('creates optional parameter with default', () {
      var param = FunctionParameter(
        name: 'value',
        type: 'float',
        required: false,
        defaultValue: 1.0,
      );

      expect(param.required, isFalse);
      expect(param.defaultValue, equals(1.0));
    });

    test('serializes to JSON correctly', () {
      var param = FunctionParameter(
        name: 'value',
        type: 'float',
        required: false,
        defaultValue: 1.0,
      );

      var json = param.toJSON();
      expect(json['name'], equals('value'));
      expect(json['type'], equals('float'));
      expect(json['required'], isFalse);
      expect(json['defaultValue'], equals(1.0));
    });
  });
}
