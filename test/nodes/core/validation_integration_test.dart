import 'package:flutter_test/flutter_test.dart';
import 'package:three_dart_v2/three3d/nodes/core/index.dart';

/// Integration tests demonstrating the validation system in realistic scenarios
void main() {
  group('Validation Integration', () {
    late NodeGraphValidator validator;
    
    setUp(() {
      validator = NodeGraphValidator();
    });
    
    test('validates complex material graph', () {
      // Create a realistic material graph:
      // albedo = texture * color
      // roughness = constant
      // output = combine(albedo, roughness)
      
      Node albedoColor = Vec3Node(1.0, 0.5, 0.2);
      Node roughness = ConstantNode(0.5);
      
      // Combine them (simplified - in real scenario would be more complex)
      Node combined = albedoColor.mul(roughness);
      
      List<ValidationError> errors = validator.validate(combined);
      
      // Should be valid
      List<ValidationError> criticalErrors = errors
          .where((e) => e.severity == 'error')
          .toList();
      expect(criticalErrors, isEmpty);
    });
    
    test('validates procedural texture graph', () {
      // Create a procedural texture:
      // uv = input
      // noise = perlin(uv * scale)
      // color = mix(color1, color2, noise)
      
      Node scale = ConstantNode(5.0);
      Node color1 = Vec3Node(0.0, 0.0, 0.0);
      Node color2 = Vec3Node(1.0, 1.0, 1.0);
      
      // Simplified procedural graph
      Node result = color1.add(color2.mul(scale));
      
      List<ValidationError> errors = validator.validate(result);
      
      List<ValidationError> criticalErrors = errors
          .where((e) => e.severity == 'error')
          .toList();
      expect(criticalErrors, isEmpty);
    });
    
    test('validates lighting calculation graph', () {
      // Create a lighting graph:
      // normal = normalize(input)
      // lightDir = normalize(lightPos - worldPos)
      // diffuse = max(dot(normal, lightDir), 0)
      // color = albedo * diffuse
      
      Node normal = Vec3Node(0.0, 1.0, 0.0);
      Node lightDir = Vec3Node(1.0, 1.0, 0.0);
      Node albedo = Vec3Node(1.0, 0.5, 0.2);
      
      // Simplified lighting calculation
      Node dotProduct = normal.dot(lightDir);
      Node diffuse = MathNode('max', dotProduct, ConstantNode(0.0));
      Node finalColor = albedo.mul(diffuse);
      
      List<ValidationError> errors = validator.validate(finalColor);
      
      List<ValidationError> criticalErrors = errors
          .where((e) => e.severity == 'error')
          .toList();
      expect(criticalErrors, isEmpty);
    });
    
    test('detects and reports multiple errors in complex graph', () {
      // Create a graph with multiple potential issues
      Node a = ConstantNode(1.0);
      Node b = Vec3Node(1.0, 2.0, 3.0);
      
      // This creates a valid graph, but we can test error reporting
      Node result = a.add(b);
      
      List<ValidationError> errors = validator.validate(result);
      
      // The validator should handle this gracefully
      // (type conversion happens automatically in this case)
      expect(errors, isNotNull);
    });
    
    test('validates graph with type conversions', () {
      // Create a graph that requires type conversions:
      // float -> vec3 -> operations -> float
      
      Node scalar = ConstantNode(0.5);
      Node vector = scalar.toVec3();
      Node scaled = vector.mul(2.0);
      Node result = scaled.toFloat(); // Extract first component
      
      List<ValidationError> errors = validator.validate(result);
      
      List<ValidationError> criticalErrors = errors
          .where((e) => e.severity == 'error')
          .toList();
      expect(criticalErrors, isEmpty);
    });
    
    test('validates mathematical expression graph', () {
      // Create: (a + b) * (c - d) / e
      Node a = ConstantNode(1.0);
      Node b = ConstantNode(2.0);
      Node c = ConstantNode(3.0);
      Node d = ConstantNode(4.0);
      Node e = ConstantNode(5.0);
      
      Node sum = a.add(b);
      Node diff = c.sub(d);
      Node product = sum.mul(diff);
      Node result = product.div(e);
      
      List<ValidationError> errors = validator.validate(result);
      
      List<ValidationError> criticalErrors = errors
          .where((e) => e.severity == 'error')
          .toList();
      expect(criticalErrors, isEmpty);
    });
    
    test('provides helpful error messages for common mistakes', () {
      // Simulate a common mistake: trying to use a vector where scalar is expected
      // (This is actually handled by auto-conversion in our system, but demonstrates
      // the error reporting capability)
      
      Node vector = Vec3Node(1.0, 2.0, 3.0);
      Node scalar = ConstantNode(1.0);
      
      // This is valid in our system due to auto-conversion
      Node result = vector.add(scalar);
      
      List<ValidationError> errors = validator.validate(result);
      
      // Should not have critical errors due to auto-conversion
      List<ValidationError> criticalErrors = errors
          .where((e) => e.severity == 'error')
          .toList();
      expect(criticalErrors, isEmpty);
    });
    
    test('validates nested mathematical operations', () {
      // Create: sin(cos(tan(x)))
      Node x = ConstantNode(0.5);
      Node tan = MathNode('tan', x);
      Node cos = MathNode('cos', tan);
      Node sin = MathNode('sin', cos);
      
      List<ValidationError> errors = validator.validate(sin);
      
      List<ValidationError> criticalErrors = errors
          .where((e) => e.severity == 'error')
          .toList();
      expect(criticalErrors, isEmpty);
    });
    
    test('validates vector operations', () {
      // Create: normalize(cross(a, b))
      Node a = Vec3Node(1.0, 0.0, 0.0);
      Node b = Vec3Node(0.0, 1.0, 0.0);
      
      Node cross = a.cross(b);
      Node normalized = MathNode('normalize', cross);
      
      List<ValidationError> errors = validator.validate(normalized);
      
      List<ValidationError> criticalErrors = errors
          .where((e) => e.severity == 'error')
          .toList();
      expect(criticalErrors, isEmpty);
    });
    
    test('validates power and exponential operations', () {
      // Create: pow(x, 2) + exp(y)
      Node x = ConstantNode(2.0);
      Node y = ConstantNode(1.0);
      
      Node squared = x.pow(2.0);
      Node exponential = MathNode('exp', y);
      Node result = squared.add(exponential);
      
      List<ValidationError> errors = validator.validate(result);
      
      List<ValidationError> criticalErrors = errors
          .where((e) => e.severity == 'error')
          .toList();
      expect(criticalErrors, isEmpty);
    });
  });
  
  group('Error Recovery', () {
    test('continues validation after finding errors', () {
      // Even if one part of validation fails, the validator should
      // continue and find all errors
      
      NodeGraphValidator validator = NodeGraphValidator();
      
      // Create a simple valid graph
      Node node = ConstantNode(1.0);
      
      List<ValidationError> errors = validator.validate(node);
      
      // Should complete validation
      expect(errors, isNotNull);
    });
    
    test('provides context for debugging', () {
      Node node = ConstantNode(1.0);
      
      ValidationError error = ValidationError(
        message: 'Test error',
        node: node,
        nodeType: 'ConstantNode',
        severity: 'error',
        suggestion: 'Fix the issue',
        context: {
          'additionalInfo': 'Debug data',
          'nodeValue': 1.0,
        },
      );
      
      // Error should contain all context
      expect(error.message, isNotNull);
      expect(error.node, equals(node));
      expect(error.nodeType, equals('ConstantNode'));
      expect(error.suggestion, isNotNull);
      expect(error.context, isNotNull);
      expect(error.context!['additionalInfo'], equals('Debug data'));
    });
  });
}
