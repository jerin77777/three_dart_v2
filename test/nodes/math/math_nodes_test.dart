import 'package:flutter_test/flutter_test.dart';
import 'package:three_dart_v2/three3d/nodes/core/node.dart' hide MathNode, OperatorNode;
import 'package:three_dart_v2/three3d/nodes/core/node_builder.dart';
import 'package:three_dart_v2/three3d/nodes/math/index.dart';

void main() {
  group('MathNode', () {
    late NodeBuilder builder;

    setUp(() {
      builder = NodeBuilder();
    });

    test('creates MathNode with unary operation', () {
      var input = ConstantNode(0.5);
      var mathNode = MathNode('sin', input);

      expect(mathNode.nodeType, equals('MathNode'));
      expect(mathNode.method, equals('sin'));
    });

    test('generates correct GLSL for unary operations', () {
      var input = ConstantNode(0.5);
      var sinNode = MathNode('sin', input);

      var glsl = sinNode.generate(builder, 'float');
      expect(glsl, equals('sin(0.5)'));
    });

    test('generates correct GLSL for binary operations', () {
      var a = ConstantNode(2.0);
      var b = ConstantNode(3.0);
      var powNode = MathNode('pow', a, b);

      var glsl = powNode.generate(builder, 'float');
      expect(glsl, equals('pow(2.0, 3.0)'));
    });

    test('generates correct GLSL for ternary operations', () {
      var a = ConstantNode(0.5);
      var b = ConstantNode(0.0);
      var c = ConstantNode(1.0);
      var mixNode = MathNode('mix', a, b, c);

      var glsl = mixNode.generate(builder, 'float');
      expect(glsl, equals('mix(0.5, 0.0, 1.0)'));
    });

    test('handles saturate special case', () {
      var input = ConstantNode(1.5);
      var saturateNode = MathNode('saturate', input);

      var glsl = saturateNode.generate(builder, 'float');
      expect(glsl, equals('clamp(1.5, 0.0, 1.0)'));
    });

    test('handles negate special case', () {
      var input = ConstantNode(1.0);
      var negateNode = MathNode('negate', input);

      var glsl = negateNode.generate(builder, 'float');
      expect(glsl, equals('(-1.0)'));
    });

    test('handles oneMinus special case', () {
      var input = ConstantNode(0.3);
      var oneMinusNode = MathNode('oneMinus', input);

      var glsl = oneMinusNode.generate(builder, 'float');
      expect(glsl, equals('(1.0 - 0.3)'));
    });

    test('handles atan2 special case', () {
      var y = ConstantNode(1.0);
      var x = ConstantNode(2.0);
      var atan2Node = MathNode('atan2', y, x);

      var glsl = atan2Node.generate(builder, 'float');
      expect(glsl, equals('atan(1.0, 2.0)'));
    });

    test('throws error for unknown unary operation', () {
      var input = ConstantNode(1.0);
      expect(
        () => MathNode('unknownOp', input),
        throwsArgumentError,
      );
    });

    test('throws error for unknown binary operation', () {
      var a = ConstantNode(1.0);
      var b = ConstantNode(2.0);
      expect(
        () => MathNode('unknownOp', a, b),
        throwsArgumentError,
      );
    });

    test('serializes to JSON correctly', () {
      var input = ConstantNode(0.5);
      var mathNode = MathNode('sin', input);

      var json = mathNode.toJSON();
      expect(json['type'], equals('MathNode'));
      expect(json['method'], equals('sin'));
      expect(json['aNode'], isNotNull);
    });

    test('convenience functions work correctly', () {
      var input = ConstantNode(0.5);

      expect(sin(input).method, equals('sin'));
      expect(cos(input).method, equals('cos'));
      expect(abs(input).method, equals('abs'));
      expect(sqrt(input).method, equals('sqrt'));
      expect(floor(input).method, equals('floor'));
      expect(ceil(input).method, equals('ceil'));
    });

    test('binary convenience functions work correctly', () {
      var a = ConstantNode(2.0);
      var b = ConstantNode(3.0);

      expect(pow(a, b).method, equals('pow'));
      expect(min(a, b).method, equals('min'));
      expect(max(a, b).method, equals('max'));
      expect(dot(a, b).method, equals('dot'));
    });

    test('ternary convenience functions work correctly', () {
      var a = ConstantNode(0.5);
      var b = ConstantNode(0.0);
      var c = ConstantNode(1.0);

      expect(mix(a, b, c).method, equals('mix'));
      expect(clamp(a, b, c).method, equals('clamp'));
      expect(smoothstep(a, b, c).method, equals('smoothstep'));
    });
  });

  group('OperatorNode', () {
    late NodeBuilder builder;

    setUp(() {
      builder = NodeBuilder();
    });

    test('creates OperatorNode with arithmetic operator', () {
      var a = ConstantNode(1.0);
      var b = ConstantNode(2.0);
      var addNode = OperatorNode('+', a, b);

      expect(addNode.nodeType, equals('OperatorNode'));
      expect(addNode.op, equals('+'));
    });

    test('generates correct GLSL for addition', () {
      var a = ConstantNode(1.0);
      var b = ConstantNode(2.0);
      var addNode = OperatorNode('+', a, b);

      var glsl = addNode.generate(builder, 'float');
      expect(glsl, equals('(1.0 + 2.0)'));
    });

    test('generates correct GLSL for subtraction', () {
      var a = ConstantNode(5.0);
      var b = ConstantNode(3.0);
      var subNode = OperatorNode('-', a, b);

      var glsl = subNode.generate(builder, 'float');
      expect(glsl, equals('(5.0 - 3.0)'));
    });

    test('generates correct GLSL for multiplication', () {
      var a = ConstantNode(2.0);
      var b = ConstantNode(3.0);
      var mulNode = OperatorNode('*', a, b);

      var glsl = mulNode.generate(builder, 'float');
      expect(glsl, equals('(2.0 * 3.0)'));
    });

    test('generates correct GLSL for division', () {
      var a = ConstantNode(6.0);
      var b = ConstantNode(2.0);
      var divNode = OperatorNode('/', a, b);

      var glsl = divNode.generate(builder, 'float');
      expect(glsl, equals('(6.0 / 2.0)'));
    });

    test('generates correct GLSL for modulo', () {
      var a = ConstantNode(7.0);
      var b = ConstantNode(3.0);
      var modNode = OperatorNode('%', a, b);

      var glsl = modNode.generate(builder, 'float');
      expect(glsl, equals('(7.0 % 3.0)'));
    });

    test('generates correct GLSL for comparison operators', () {
      var a = ConstantNode(1.0);
      var b = ConstantNode(2.0);

      expect(OperatorNode('<', a, b).generate(builder, 'bool'), equals('(1.0 < 2.0)'));
      expect(OperatorNode('<=', a, b).generate(builder, 'bool'), equals('(1.0 <= 2.0)'));
      expect(OperatorNode('>', a, b).generate(builder, 'bool'), equals('(1.0 > 2.0)'));
      expect(OperatorNode('>=', a, b).generate(builder, 'bool'), equals('(1.0 >= 2.0)'));
      expect(OperatorNode('==', a, b).generate(builder, 'bool'), equals('(1.0 == 2.0)'));
      expect(OperatorNode('!=', a, b).generate(builder, 'bool'), equals('(1.0 != 2.0)'));
    });

    test('generates correct GLSL for logical operators', () {
      var a = ConstantNode(1.0);
      var b = ConstantNode(0.0);

      expect(OperatorNode('&&', a, b).generate(builder, 'bool'), equals('(1.0 && 0.0)'));
      expect(OperatorNode('||', a, b).generate(builder, 'bool'), equals('(1.0 || 0.0)'));
    });

    test('generates correct GLSL for bitwise operators', () {
      var a = ConstantNode(5.0);
      var b = ConstantNode(3.0);

      expect(OperatorNode('&', a, b).generate(builder, 'int'), equals('(5.0 & 3.0)'));
      expect(OperatorNode('|', a, b).generate(builder, 'int'), equals('(5.0 | 3.0)'));
      expect(OperatorNode('^', a, b).generate(builder, 'int'), equals('(5.0 ^ 3.0)'));
      expect(OperatorNode('<<', a, b).generate(builder, 'int'), equals('(5.0 << 3.0)'));
      expect(OperatorNode('>>', a, b).generate(builder, 'int'), equals('(5.0 >> 3.0)'));
    });

    test('throws error for unknown operator', () {
      var a = ConstantNode(1.0);
      var b = ConstantNode(2.0);
      expect(
        () => OperatorNode('???', a, b),
        throwsArgumentError,
      );
    });

    test('identifies operator types correctly', () {
      var a = ConstantNode(1.0);
      var b = ConstantNode(2.0);

      expect(OperatorNode('+', a, b).isArithmetic, isTrue);
      expect(OperatorNode('<', a, b).isComparison, isTrue);
      expect(OperatorNode('&&', a, b).isLogical, isTrue);
      expect(OperatorNode('&', a, b).isBitwise, isTrue);
    });

    test('serializes to JSON correctly', () {
      var a = ConstantNode(1.0);
      var b = ConstantNode(2.0);
      var addNode = OperatorNode('+', a, b);

      var json = addNode.toJSON();
      expect(json['type'], equals('OperatorNode'));
      expect(json['op'], equals('+'));
      expect(json['aNode'], isNotNull);
      expect(json['bNode'], isNotNull);
    });

    test('convenience functions work correctly', () {
      var a = ConstantNode(1.0);
      var b = ConstantNode(2.0);

      expect(add(a, b).op, equals('+'));
      expect(sub(a, b).op, equals('-'));
      expect(mul(a, b).op, equals('*'));
      expect(div(a, b).op, equals('/'));
      expect(modulo(a, b).op, equals('%'));
    });
  });

  group('ConditionalNode', () {
    late NodeBuilder builder;

    setUp(() {
      builder = NodeBuilder();
    });

    test('creates ConditionalNode', () {
      var cond = ConstantNode(1.0);
      var ifTrue = ConstantNode(2.0);
      var ifFalse = ConstantNode(3.0);
      var condNode = ConditionalNode(cond, ifTrue, ifFalse);

      expect(condNode.nodeType, equals('ConditionalNode'));
    });

    test('generates correct GLSL for ternary operator', () {
      var cond = OperatorNode('>', ConstantNode(1.0), ConstantNode(0.5));
      var ifTrue = ConstantNode(10.0);
      var ifFalse = ConstantNode(20.0);
      var condNode = ConditionalNode(cond, ifTrue, ifFalse);

      var glsl = condNode.generate(builder, 'float');
      expect(glsl, contains('?'));
      expect(glsl, contains(':'));
      expect(glsl, contains('10.0'));
      expect(glsl, contains('20.0'));
    });

    test('serializes to JSON correctly', () {
      var cond = ConstantNode(1.0);
      var ifTrue = ConstantNode(2.0);
      var ifFalse = ConstantNode(3.0);
      var condNode = ConditionalNode(cond, ifTrue, ifFalse);

      var json = condNode.toJSON();
      expect(json['type'], equals('ConditionalNode'));
      expect(json['condNode'], isNotNull);
      expect(json['ifNode'], isNotNull);
      expect(json['elseNode'], isNotNull);
    });

    test('convenience function works correctly', () {
      var cond = ConstantNode(1.0);
      var ifTrue = ConstantNode(2.0);
      var ifFalse = ConstantNode(3.0);

      var node = conditional(cond, ifTrue, ifFalse);
      expect(node, isA<ConditionalNode>());
    });

    test('boolToFloat convenience function works', () {
      var cond = OperatorNode('>', ConstantNode(1.0), ConstantNode(0.5));
      var node = boolToFloat(cond);

      var glsl = node.generate(builder, 'float');
      expect(glsl, contains('1.0'));
      expect(glsl, contains('0.0'));
    });
  });

  group('SelectNode', () {
    late NodeBuilder builder;

    setUp(() {
      builder = NodeBuilder();
    });

    test('creates SelectNode', () {
      var cond = ConstantNode(1.0);
      var trueVal = ConstantNode(2.0);
      var falseVal = ConstantNode(3.0);
      var selectNode = SelectNode(cond, trueVal, falseVal);

      expect(selectNode.nodeType, equals('SelectNode'));
    });

    test('generates correct GLSL using mix', () {
      var cond = ConstantNode(1.0);
      var trueVal = ConstantNode(2.0);
      var falseVal = ConstantNode(3.0);
      var selectNode = SelectNode(cond, trueVal, falseVal);

      var glsl = selectNode.generate(builder, 'float');
      expect(glsl, contains('mix'));
      expect(glsl, contains('3.0')); // false value first
      expect(glsl, contains('2.0')); // true value second
    });
  });

  group('BitcastNode', () {
    late NodeBuilder builder;

    setUp(() {
      builder = NodeBuilder();
    });

    test('creates BitcastNode', () {
      var input = ConstantNode(1.0);
      var bitcastNode = BitcastNode(input, 'int');

      expect(bitcastNode.nodeType, equals('BitcastNode'));
      expect(bitcastNode.targetType, equals('int'));
    });

    test('generates correct GLSL for float to int', () {
      var input = ConstantNode(1.0);
      var bitcastNode = BitcastNode(input, 'int');

      var glsl = bitcastNode.generate(builder, 'int');
      expect(glsl, equals('floatBitsToInt(1.0)'));
    });

    test('generates correct GLSL for float to uint', () {
      var input = ConstantNode(1.0);
      var bitcastNode = BitcastNode(input, 'uint');

      var glsl = bitcastNode.generate(builder, 'uint');
      expect(glsl, equals('floatBitsToUint(1.0)'));
    });

    test('generates correct GLSL for int to float', () {
      var input = ConstantNode(1.0);
      var bitcastNode = BitcastNode(input, 'float');

      var glsl = bitcastNode.generate(builder, 'float');
      expect(glsl, equals('intBitsToFloat(1.0)'));
    });

    test('throws error for unsupported target type', () {
      var input = ConstantNode(1.0);
      expect(
        () => BitcastNode(input, 'vec3'),
        throwsArgumentError,
      );
    });

    test('convenience functions work correctly', () {
      var input = ConstantNode(1.0);

      expect(floatBitsToInt(input).targetType, equals('int'));
      expect(floatBitsToUint(input).targetType, equals('uint'));
      expect(intBitsToFloat(input).targetType, equals('float'));
    });
  });

  group('BitcountNode', () {
    late NodeBuilder builder;

    setUp(() {
      builder = NodeBuilder();
    });

    test('creates BitcountNode', () {
      var input = ConstantNode(15.0);
      var bitcountNode = BitcountNode(input);

      expect(bitcountNode.nodeType, equals('BitcountNode'));
    });

    test('generates correct GLSL', () {
      var input = ConstantNode(15.0);
      var bitcountNode = BitcountNode(input);

      var glsl = bitcountNode.generate(builder, 'int');
      expect(glsl, equals('bitCount(15.0)'));
    });

    test('convenience function works correctly', () {
      var input = ConstantNode(15.0);
      var node = bitCount(input);

      expect(node, isA<BitcountNode>());
    });
  });

  group('PackFloatNode', () {
    late NodeBuilder builder;

    setUp(() {
      builder = NodeBuilder();
    });

    test('creates PackFloatNode with 2 components', () {
      var nodes = [ConstantNode(1.0), ConstantNode(2.0)];
      var packNode = PackFloatNode(nodes);

      expect(packNode.nodeType, equals('PackFloatNode'));
    });

    test('generates correct GLSL for vec2', () {
      var nodes = [ConstantNode(1.0), ConstantNode(2.0)];
      var packNode = PackFloatNode(nodes);

      var glsl = packNode.generate(builder, 'vec2');
      expect(glsl, equals('vec2(1.0, 2.0)'));
    });

    test('generates correct GLSL for vec3', () {
      var nodes = [ConstantNode(1.0), ConstantNode(2.0), ConstantNode(3.0)];
      var packNode = PackFloatNode(nodes);

      var glsl = packNode.generate(builder, 'vec3');
      expect(glsl, equals('vec3(1.0, 2.0, 3.0)'));
    });

    test('generates correct GLSL for vec4', () {
      var nodes = [
        ConstantNode(1.0),
        ConstantNode(2.0),
        ConstantNode(3.0),
        ConstantNode(4.0)
      ];
      var packNode = PackFloatNode(nodes);

      var glsl = packNode.generate(builder, 'vec4');
      expect(glsl, equals('vec4(1.0, 2.0, 3.0, 4.0)'));
    });

    test('throws error for empty list', () {
      expect(
        () => PackFloatNode([]),
        throwsArgumentError,
      );
    });

    test('throws error for too many components', () {
      var nodes = List.generate(5, (_) => ConstantNode(1.0));
      expect(
        () => PackFloatNode(nodes),
        throwsArgumentError,
      );
    });
  });

  group('UnpackFloatNode', () {
    late NodeBuilder builder;

    setUp(() {
      builder = NodeBuilder();
    });

    test('creates UnpackFloatNode', () {
      var input = Vec3Node(1.0, 2.0, 3.0);
      var unpackNode = UnpackFloatNode(input, 'x');

      expect(unpackNode.nodeType, equals('UnpackFloatNode'));
      expect(unpackNode.component, equals('x'));
    });

    test('generates correct GLSL for x component', () {
      var input = Vec3Node(1.0, 2.0, 3.0);
      var unpackNode = UnpackFloatNode(input, 'x');

      var glsl = unpackNode.generate(builder, 'float');
      expect(glsl, contains('.x'));
    });

    test('generates correct GLSL for rgb components', () {
      var input = Vec3Node(1.0, 2.0, 3.0);

      expect(UnpackFloatNode(input, 'r').generate(builder, 'float'), contains('.r'));
      expect(UnpackFloatNode(input, 'g').generate(builder, 'float'), contains('.g'));
      expect(UnpackFloatNode(input, 'b').generate(builder, 'float'), contains('.b'));
    });

    test('throws error for invalid component', () {
      var input = Vec3Node(1.0, 2.0, 3.0);
      expect(
        () => UnpackFloatNode(input, 'invalid'),
        throwsArgumentError,
      );
    });

    test('convenience functions work correctly', () {
      var input = Vec4Node(1.0, 2.0, 3.0, 4.0);

      expect(extractX(input).component, equals('x'));
      expect(extractY(input).component, equals('y'));
      expect(extractZ(input).component, equals('z'));
      expect(extractW(input).component, equals('w'));
      expect(extractR(input).component, equals('r'));
      expect(extractG(input).component, equals('g'));
      expect(extractB(input).component, equals('b'));
      expect(extractA(input).component, equals('a'));
    });
  });

  group('BitFieldExtractNode', () {
    late NodeBuilder builder;

    setUp(() {
      builder = NodeBuilder();
    });

    test('creates BitFieldExtractNode', () {
      var value = ConstantNode(255.0);
      var offset = ConstantNode(4.0);
      var bits = ConstantNode(4.0);
      var extractNode = BitFieldExtractNode(value, offset, bits);

      expect(extractNode.nodeType, equals('BitFieldExtractNode'));
    });

    test('generates correct GLSL', () {
      var value = ConstantNode(255.0);
      var offset = ConstantNode(4.0);
      var bits = ConstantNode(4.0);
      var extractNode = BitFieldExtractNode(value, offset, bits);

      var glsl = extractNode.generate(builder, 'int');
      expect(glsl, equals('bitfieldExtract(255.0, 4.0, 4.0)'));
    });
  });

  group('BitFieldInsertNode', () {
    late NodeBuilder builder;

    setUp(() {
      builder = NodeBuilder();
    });

    test('creates BitFieldInsertNode', () {
      var base = ConstantNode(0.0);
      var insert = ConstantNode(15.0);
      var offset = ConstantNode(4.0);
      var bits = ConstantNode(4.0);
      var insertNode = BitFieldInsertNode(base, insert, offset, bits);

      expect(insertNode.nodeType, equals('BitFieldInsertNode'));
    });

    test('generates correct GLSL', () {
      var base = ConstantNode(0.0);
      var insert = ConstantNode(15.0);
      var offset = ConstantNode(4.0);
      var bits = ConstantNode(4.0);
      var insertNode = BitFieldInsertNode(base, insert, offset, bits);

      var glsl = insertNode.generate(builder, 'int');
      expect(glsl, equals('bitfieldInsert(0.0, 15.0, 4.0, 4.0)'));
    });
  });
}
