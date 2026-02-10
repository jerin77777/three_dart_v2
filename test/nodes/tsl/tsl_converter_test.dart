import 'package:flutter_test/flutter_test.dart';
import 'package:three_dart_v2/three3d/nodes/tsl/tsl_tokenizer.dart';
import 'package:three_dart_v2/three3d/nodes/tsl/tsl_parser.dart';
import 'package:three_dart_v2/three3d/nodes/tsl/tsl_converter.dart';
import 'package:three_dart_v2/three3d/nodes/core/node.dart';
import 'package:three_dart_v2/three3d/nodes/math/operator_node.dart' as op;
import 'package:three_dart_v2/three3d/nodes/math/math_node.dart' as math;
import 'package:three_dart_v2/three3d/nodes/math/conditional_node.dart' as cond;
import 'package:three_dart_v2/three3d/nodes/utils/join_node.dart' as join;
import 'package:three_dart_v2/three3d/nodes/utils/split_node.dart' as split;

void main() {
  group('TSLConverter', () {
    test('converts simple variable declaration', () {
      String tslCode = '''
        var x: float = 1.0;
      ''';
      
      TSLTokenizer tokenizer = TSLTokenizer(tslCode);
      List<Token> tokens = tokenizer.tokenize();
      
      TSLParser parser = TSLParser(tokens);
      ProgramNode program = parser.parse();
      
      TSLConverter converter = TSLConverter();
      Node result = converter.convert(program);
      
      expect(result, isNotNull);
      expect(result, isA<ConstantNode>());
    });
    
    test('converts arithmetic expression', () {
      String tslCode = '''
        var a: float = 2.0;
        var b: float = 3.0;
        var c: float = a + b;
      ''';
      
      TSLTokenizer tokenizer = TSLTokenizer(tslCode);
      List<Token> tokens = tokenizer.tokenize();
      
      TSLParser parser = TSLParser(tokens);
      ProgramNode program = parser.parse();
      
      TSLConverter converter = TSLConverter();
      Node result = converter.convert(program);
      
      expect(result, isNotNull);
      expect(result, isA<op.OperatorNode>());
    });
    
    test('converts function declaration', () {
      String tslCode = '''
        fn add(float a, float b) -> float {
          return a + b;
        }
      ''';
      
      TSLTokenizer tokenizer = TSLTokenizer(tslCode);
      List<Token> tokens = tokenizer.tokenize();
      
      TSLParser parser = TSLParser(tokens);
      ProgramNode program = parser.parse();
      
      TSLConverter converter = TSLConverter();
      Node result = converter.convert(program);
      
      expect(result, isNotNull);
      expect(result.nodeType, equals('FunctionNode'));
    });
    
    test('converts function call', () {
      String tslCode = '''
        var x: float = sin(1.0);
      ''';
      
      TSLTokenizer tokenizer = TSLTokenizer(tslCode);
      List<Token> tokens = tokenizer.tokenize();
      
      TSLParser parser = TSLParser(tokens);
      ProgramNode program = parser.parse();
      
      TSLConverter converter = TSLConverter();
      Node result = converter.convert(program);
      
      expect(result, isNotNull);
      expect(result, isA<math.MathNode>());
    });
    
    test('converts vector constructor', () {
      String tslCode = '''
        var v: vec3 = vec3(1.0, 2.0, 3.0);
      ''';
      
      TSLTokenizer tokenizer = TSLTokenizer(tslCode);
      List<Token> tokens = tokenizer.tokenize();
      
      TSLParser parser = TSLParser(tokens);
      ProgramNode program = parser.parse();
      
      TSLConverter converter = TSLConverter();
      Node result = converter.convert(program);
      
      expect(result, isNotNull);
      expect(result, isA<join.JoinNode>());
    });
    
    test('converts conditional expression', () {
      String tslCode = '''
        var x: float = 1.0;
        var result: float = if (x > 0.5) { 1.0; } else { 0.0; };
      ''';
      
      TSLTokenizer tokenizer = TSLTokenizer(tslCode);
      List<Token> tokens = tokenizer.tokenize();
      
      TSLParser parser = TSLParser(tokens);
      ProgramNode program = parser.parse();
      
      TSLConverter converter = TSLConverter();
      Node result = converter.convert(program);
      
      expect(result, isNotNull);
      expect(result, isA<cond.ConditionalNode>());
    });
    
    test('converts member access', () {
      String tslCode = '''
        var v: vec3 = vec3(1.0, 2.0, 3.0);
        var x: float = v.x;
      ''';
      
      TSLTokenizer tokenizer = TSLTokenizer(tslCode);
      List<Token> tokens = tokenizer.tokenize();
      
      TSLParser parser = TSLParser(tokens);
      ProgramNode program = parser.parse();
      
      TSLConverter converter = TSLConverter();
      Node result = converter.convert(program);
      
      expect(result, isNotNull);
      expect(result, isA<split.SplitNode>());
    });
    
    test('throws error for undefined variable', () {
      String tslCode = '''
        var x: float = undefinedVar;
      ''';
      
      TSLTokenizer tokenizer = TSLTokenizer(tslCode);
      List<Token> tokens = tokenizer.tokenize();
      
      TSLParser parser = TSLParser(tokens);
      ProgramNode program = parser.parse();
      
      TSLConverter converter = TSLConverter();
      
      expect(
        () => converter.convert(program),
        throwsA(isA<TSLConversionError>()),
      );
    });
    
    test('throws error for empty program', () {
      String tslCode = '';
      
      TSLTokenizer tokenizer = TSLTokenizer(tslCode);
      List<Token> tokens = tokenizer.tokenize();
      
      TSLParser parser = TSLParser(tokens);
      ProgramNode program = parser.parse();
      
      TSLConverter converter = TSLConverter();
      
      expect(
        () => converter.convert(program),
        throwsA(isA<TSLConversionError>()),
      );
    });
  });
  
  group('TSL.parse', () {
    test('parses and converts TSL code in one call', () {
      String tslCode = '''
        var x: float = 1.0;
        var y: float = 2.0;
        var result: float = x + y;
      ''';
      
      Node result = TSL.parse(tslCode);
      
      expect(result, isNotNull);
      expect(result, isA<op.OperatorNode>());
    });
  });
}
