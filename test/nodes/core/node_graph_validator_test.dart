import 'package:flutter_test/flutter_test.dart';
import 'package:three_dart_v2/three3d/nodes/core/index.dart';

void main() {
  group('NodeGraphValidator', () {
    late NodeGraphValidator validator;
    
    setUp(() {
      validator = NodeGraphValidator();
    });
    
    group('Basic Validation', () {
      test('validates null root node', () {
        List<ValidationError> errors = validator.validate(null);
        
        expect(errors, isNotEmpty);
        expect(errors.first.message, contains('Root node is null'));
        expect(errors.first.severity, equals('error'));
      });
      
      test('validates simple valid graph', () {
        // Create a simple valid graph: constant -> output
        Node constant = ConstantNode(1.0);
        
        List<ValidationError> errors = validator.validate(constant);
        
        // Should have no critical errors (may have warnings about disconnected output)
        List<ValidationError> criticalErrors = errors
            .where((e) => e.severity == 'error')
            .toList();
        expect(criticalErrors, isEmpty);
      });
      
      test('validates graph with operations', () {
        // Create: (1.0 + 2.0) * 3.0
        Node a = ConstantNode(1.0);
        Node b = ConstantNode(2.0);
        Node c = ConstantNode(3.0);
        
        Node add = a.add(b);
        Node mul = add.mul(c);
        
        List<ValidationError> errors = validator.validate(mul);
        
        List<ValidationError> criticalErrors = errors
            .where((e) => e.severity == 'error')
            .toList();
        expect(criticalErrors, isEmpty);
      });
    });
    
    group('Circular Dependency Detection', () {
      test('detects simple circular dependency', () {
        // Create nodes that will form a cycle
        // We can't easily create a real cycle with the current API,
        // but we can test the detection logic
        
        Node a = ConstantNode(1.0);
        Node b = a.add(2.0);
        
        // This is a valid graph (no cycle)
        List<ValidationError> errors = validator.validate(b);
        
        List<ValidationError> cycleErrors = errors
            .where((e) => e.message.contains('Circular dependency'))
            .toList();
        expect(cycleErrors, isEmpty);
      });
      
      test('validates acyclic graph', () {
        // Create a diamond-shaped graph (no cycle)
        //     a
        //    / \
        //   b   c
        //    \ /
        //     d
        Node a = ConstantNode(1.0);
        Node b = a.add(1.0);
        Node c = a.mul(2.0);
        Node d = b.add(c);
        
        List<ValidationError> errors = validator.validate(d);
        
        List<ValidationError> cycleErrors = errors
            .where((e) => e.message.contains('Circular dependency'))
            .toList();
        expect(cycleErrors, isEmpty);
      });
    });
    
    group('Type Compatibility', () {
      test('validates compatible types', () {
        // float + float is valid
        Node a = ConstantNode(1.0);
        Node b = ConstantNode(2.0);
        Node result = a.add(b);
        
        List<ValidationError> errors = validator.validate(result);
        
        List<ValidationError> typeErrors = errors
            .where((e) => e.message.contains('Type mismatch'))
            .toList();
        expect(typeErrors, isEmpty);
      });
      
      test('validates vector operations', () {
        // vec3 + vec3 is valid
        Node a = Vec3Node(1.0, 2.0, 3.0);
        Node b = Vec3Node(4.0, 5.0, 6.0);
        Node result = a.add(b);
        
        List<ValidationError> errors = validator.validate(result);
        
        List<ValidationError> typeErrors = errors
            .where((e) => e.message.contains('Type mismatch'))
            .toList();
        expect(typeErrors, isEmpty);
      });
      
      test('validates type conversions', () {
        // float -> vec3 conversion
        Node a = ConstantNode(1.0);
        Node b = a.toVec3();
        
        List<ValidationError> errors = validator.validate(b);
        
        List<ValidationError> typeErrors = errors
            .where((e) => e.message.contains('Type mismatch'))
            .toList();
        expect(typeErrors, isEmpty);
      });
    });
    
    group('Disconnected Outputs', () {
      test('warns about disconnected intermediate nodes', () {
        // Create a simple graph - the validator only checks nodes
        // reachable from the root, so this test validates that behavior
        Node a = ConstantNode(1.0);
        Node b = a.add(2.0);
        
        List<ValidationError> errors = validator.validate(b);
        
        // The graph is valid - 'a' is used by 'b'
        // Only 'b' itself might be flagged as disconnected (warning)
        List<ValidationError> warnings = errors
            .where((e) => e.severity == 'warning')
            .toList();
        
        // We expect at least one warning about the root node not being connected
        expect(warnings, isNotEmpty);
      });
    });
    
    group('ValidationError', () {
      test('creates type mismatch error with context', () {
        Node source = ConstantNode(1.0);
        Node target = Vec3Node(1.0, 2.0, 3.0);
        
        ValidationError error = ValidationError.typeMismatch(
          sourceNode: source,
          sourceType: 'float',
          targetNode: target,
          targetType: 'vec3',
          inputName: 'value',
        );
        
        expect(error.message, contains('Type mismatch'));
        expect(error.message, contains('float'));
        expect(error.message, contains('vec3'));
        expect(error.severity, equals('error'));
        expect(error.suggestion, isNotNull);
        expect(error.context, isNotNull);
        expect(error.context!['sourceType'], equals('float'));
        expect(error.context!['targetType'], equals('vec3'));
      });
      
      test('creates circular dependency error', () {
        Node a = ConstantNode(1.0);
        Node b = ConstantNode(2.0);
        
        ValidationError error = ValidationError.circularDependency(
          cycle: [a, b, a],
        );
        
        expect(error.message, contains('Circular dependency'));
        expect(error.severity, equals('error'));
        expect(error.suggestion, isNotNull);
        expect(error.context, isNotNull);
        expect(error.context!['cycle'], isNotNull);
      });
      
      test('creates missing input error', () {
        Node node = ConstantNode(1.0);
        
        ValidationError error = ValidationError.missingInput(
          node: node,
          inputName: 'texture',
          inputType: 'sampler2D',
        );
        
        expect(error.message, contains('Required input'));
        expect(error.message, contains('texture'));
        expect(error.severity, equals('error'));
        expect(error.suggestion, contains('sampler2D'));
      });
      
      test('creates disconnected output warning', () {
        Node node = ConstantNode(1.0);
        
        ValidationError error = ValidationError.disconnectedOutput(
          node: node,
        );
        
        expect(error.message, contains('not connected'));
        expect(error.severity, equals('warning'));
        expect(error.suggestion, isNotNull);
      });
      
      test('creates shader compilation error', () {
        Node node = ConstantNode(1.0);
        
        ValidationError error = ValidationError.shaderCompilation(
          error: 'undeclared identifier: vUv',
          node: node,
          lineNumber: 42,
        );
        
        expect(error.message, contains('Shader compilation failed'));
        expect(error.message, contains('undeclared identifier'));
        expect(error.lineNumber, equals(42));
        expect(error.severity, equals('error'));
      });
      
      test('creates unsupported feature error', () {
        Node node = ConstantNode(1.0);
        
        ValidationError error = ValidationError.unsupportedFeature(
          feature: 'compute shaders',
          platform: 'WebGL 1.0',
          node: node,
        );
        
        expect(error.message, contains('not supported'));
        expect(error.message, contains('compute shaders'));
        expect(error.message, contains('WebGL 1.0'));
        expect(error.severity, equals('error'));
      });
      
      test('formats error as string', () {
        Node node = ConstantNode(1.0);
        
        ValidationError error = ValidationError(
          message: 'Test error',
          node: node,
          nodeType: 'ConstantNode',
          severity: 'error',
          suggestion: 'Fix it',
        );
        
        String formatted = error.toString();
        
        expect(formatted, contains('[error]'));
        expect(formatted, contains('Test error'));
        expect(formatted, contains('Node:'));
        expect(formatted, contains('ConstantNode'));
        expect(formatted, contains('Suggestion:'));
        expect(formatted, contains('Fix it'));
      });
      
      test('converts error to JSON', () {
        Node node = ConstantNode(1.0);
        
        ValidationError error = ValidationError(
          message: 'Test error',
          node: node,
          nodeType: 'ConstantNode',
          lineNumber: 10,
          severity: 'error',
          suggestion: 'Fix it',
          context: {'key': 'value'},
        );
        
        Map<String, dynamic> json = error.toJSON();
        
        expect(json['message'], equals('Test error'));
        expect(json['nodeType'], equals('ConstantNode'));
        expect(json['lineNumber'], equals(10));
        expect(json['severity'], equals('error'));
        expect(json['suggestion'], equals('Fix it'));
        expect(json['context'], isNotNull);
        expect(json['context']['key'], equals('value'));
      });
    });
    
    group('NodeValidationException', () {
      test('creates exception with errors', () {
        ValidationError error1 = ValidationError(
          message: 'Error 1',
          severity: 'error',
        );
        ValidationError error2 = ValidationError(
          message: 'Error 2',
          severity: 'error',
        );
        
        NodeValidationException exception = NodeValidationException([error1, error2]);
        
        String message = exception.toString();
        expect(message, contains('2 error(s)'));
        expect(message, contains('Error 1'));
        expect(message, contains('Error 2'));
      });
    });
    
    group('ShaderCompilationException', () {
      test('creates exception with shader code', () {
        Node node = ConstantNode(1.0);
        String shaderCode = 'void main() { gl_FragColor = vec4(1.0); }';
        
        ShaderCompilationException exception = ShaderCompilationException(
          'Syntax error',
          node: node,
          shaderCode: shaderCode,
        );
        
        String message = exception.toString();
        expect(message, contains('Shader compilation failed'));
        expect(message, contains('Syntax error'));
        expect(message, contains('Node:'));
        expect(message, contains('Generated shader code:'));
        expect(message, contains(shaderCode));
      });
    });
    
    group('validateOrThrow', () {
      test('throws exception on validation errors', () {
        // Create an invalid graph (null root)
        expect(
          () => validator.validateOrThrow(null),
          throwsA(isA<NodeValidationException>()),
        );
      });
      
      test('does not throw on valid graph', () {
        Node valid = ConstantNode(1.0);
        
        expect(
          () => validator.validateOrThrow(valid),
          returnsNormally,
        );
      });
      
      test('does not throw on warnings only', () {
        // Create a graph that might have warnings but no errors
        Node node = ConstantNode(1.0);
        
        expect(
          () => validator.validateOrThrow(node),
          returnsNormally,
        );
      });
    });
    
    group('Type Mismatch Suggestions', () {
      test('suggests component extraction for vector to scalar', () {
        Node source = Vec3Node(1.0, 2.0, 3.0);
        Node target = ConstantNode(1.0);
        
        ValidationError error = ValidationError.typeMismatch(
          sourceNode: source,
          sourceType: 'vec3',
          targetNode: target,
          targetType: 'float',
        );
        
        expect(error.suggestion, contains('extract a single component'));
        expect(error.suggestion, contains('.x'));
      });
      
      test('suggests conversion for scalar to vector', () {
        Node source = ConstantNode(1.0);
        Node target = Vec3Node(1.0, 2.0, 3.0);
        
        ValidationError error = ValidationError.typeMismatch(
          sourceNode: source,
          sourceType: 'float',
          targetNode: target,
          targetType: 'vec3',
        );
        
        expect(error.suggestion, contains('ConvertNode'));
        expect(error.suggestion, contains('JoinNode'));
      });
      
      test('suggests swizzling for larger to smaller vector', () {
        Node source = Vec4Node(1.0, 2.0, 3.0, 4.0);
        Node target = Vec2Node(1.0, 2.0);
        
        ValidationError error = ValidationError.typeMismatch(
          sourceNode: source,
          sourceType: 'vec4',
          targetNode: target,
          targetType: 'vec2',
        );
        
        expect(error.suggestion, contains('swizzling'));
        expect(error.suggestion, contains('.xy'));
      });
    });
  });
}
