import 'package:flutter_gl/flutter_gl.dart';

class Matrix2 {
  String type = "Matrix2";
  late Float32Array elements;

  Matrix2([double? n11, double? n12, double? n21, double? n22]) {
    elements = Float32Array.from([1, 0, 0, 1]);

    if (n11 != null) {
      set(n11, n12!, n21!, n22!);
    }
  }

  Matrix2 set(double n11, double n12, double n21, double n22) {
    var te = elements;

    te[0] = n11;
    te[2] = n12;
    te[1] = n21;
    te[3] = n22;

    return this;
  }

  Matrix2 identity() {
    set(1, 0, 0, 1);
    return this;
  }

  Matrix2 fromArray(List<num> array, {int offset = 0}) {
    for (var i = 0; i < 4; i++) {
      elements[i] = array[i + offset].toDouble();
    }
    return this;
  }

  Matrix2 copy(Matrix2 m) {
    var te = elements;
    var me = m.elements;

    te[0] = me[0];
    te[1] = me[1];
    te[2] = me[2];
    te[3] = me[3];

    return this;
  }

  Matrix2 clone() {
    return Matrix2().copy(this);
  }

  bool equals(Matrix2 matrix) {
    var te = elements;
    var me = matrix.elements;

    for (var i = 0; i < 4; i++) {
      if (te[i] != me[i]) return false;
    }

    return true;
  }

  List<num> toArray(List<num> array, {int offset = 0}) {
    var te = elements;

    array[offset] = te[0];
    array[offset + 1] = te[1];
    array[offset + 2] = te[2];
    array[offset + 3] = te[3];

    return array;
  }

  void dispose() {
    elements.dispose();
  }
}
