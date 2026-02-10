
import 'package:three_dart_v2/three3d/core/event_dispatcher.dart';
import 'package:three_dart_v2/three3d/constants.dart';
import 'package:three_dart_v2/three3d/core/uniform.dart';

var _id = 0;

class UniformsGroup with EventDispatcher {
  bool isUniformsGroup = true;
  late int id;
  String name = '';
  int usage = StaticDrawUsage;
  List<Uniform> uniforms = [];
  
  // Extra property to hold binding point index assigned by renderer
  int? bindingPointIndex;

  // Extra properties assigned by WebGLUniformsGroups
  // uniformsGroup.__size
  // uniformsGroup.__cache
  // uniformsGroup.__data (on uniform object, not group)
  // uniformsGroup.__offset (on uniform object)
  // I should add these fields to UniformsGroup and Uniform classes?
  // Or use Expando/Map in WebGLUniformsGroups?
  // UniformsGroup in JS is extensible. Dart class is closed.
  // I should add these fields to the class definition to support renderer logic.
  
  int? size; // __size
  Map<String, dynamic>? cache; // __cache

  UniformsGroup() {
    id = _id++;
  }

  UniformsGroup add(Uniform uniform) {
    uniforms.add(uniform);
    return this;
  }

  UniformsGroup remove(Uniform uniform) {
    uniforms.remove(uniform);
    return this;
  }

  UniformsGroup setName(String name) {
    this.name = name;
    return this;
  }

  UniformsGroup setUsage(int value) {
    usage = value;
    return this;
  }

  dispose() {
    dispatchEvent(Event({"type": "dispose", "target": this}));
  }

  UniformsGroup copy(UniformsGroup source) {
    name = source.name;
    usage = source.usage;

    var uniformsSource = source.uniforms;

    uniforms.clear();

    for (var i = 0; i < uniformsSource.length; i++) {
        uniforms.add(uniformsSource[i].clone());
    }

    return this;
  }

  UniformsGroup clone() {
    return UniformsGroup().copy(this);
  }
}
