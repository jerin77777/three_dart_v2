
import 'dart:typed_data';

class Uniform {
  dynamic value;

  // Internal properties for WebGLUniformsGroups
  Float32List? data;
  int? offset;

  Uniform(this.value);

  Uniform clone() {
    return Uniform(value.clone != null ? value.clone() : value);
  }
}
